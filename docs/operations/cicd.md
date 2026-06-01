# CI/CD Pipeline

The pipeline runs on GitHub Actions and triggers on every push to `main`. It builds both application images, pushes them to ECR, and deploys to EKS via Helm — no manual steps required after a push.


## Pipeline Overview

```
push to main
  └─▶ Checkout
  └─▶ AWS authentication (OIDC)
  └─▶ Build + tag Docker images (FastAPI, Website)
  └─▶ Push images to ECR
  └─▶ Update kubeconfig
  └─▶ helm upgrade --install (FastAPI)
  └─▶ helm upgrade --install (Website)
```


## Workflow File

**Location:** `.github/workflows/deploy.yml`  
**Trigger:** `push` to `main`

```yaml
on:
  push:
    branches: [main]

permissions:
  id-token: write   # required for OIDC token issuance
  contents: read
```


## Steps

### 1. AWS Authentication

Uses OIDC federation — no static AWS credentials are stored in GitHub secrets.

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/eks-observability-github-actions-role
    aws-region: us-east-1
```

GitHub issues a short-lived OIDC token per workflow run. AWS STS exchanges it for temporary credentials scoped to the GitHub Actions IAM role. The trust policy restricts assumption to this repository only.

**Validation:**
```bash
aws sts get-caller-identity
# ARN must match the GitHub Actions role, not an IAM user
```

### 2. ECR Authentication

```yaml
- name: Login to ECR
  uses: aws-actions/amazon-ecr-login@v2
```

This action retrieves a temporary ECR token and configures Docker. The token is valid for 12 hours — sufficient for any single workflow run.

### 3. Build & Push Images

Both images are built in parallel, tagged with the commit SHA for immutability:

```yaml
env:
  ECR_REGISTRY: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
  IMAGE_TAG: ${{ github.sha }}

- name: Build and push FastAPI
  run: |
    docker build -t $ECR_REGISTRY/eks-observability-fastapi:$IMAGE_TAG ./apps/fastapi
    docker push $ECR_REGISTRY/eks-observability-fastapi:$IMAGE_TAG

- name: Build and push Website
  run: |
    docker build -t $ECR_REGISTRY/eks-observability-website:$IMAGE_TAG ./apps/website
    docker push $ECR_REGISTRY/eks-observability-website:$IMAGE_TAG
```

Using `$GITHUB_SHA` as the image tag ensures every deployment references a specific, immutable image. The `latest` tag is not used.

### 4. Cluster Access

```yaml
- name: Update kubeconfig
  run: |
    aws eks update-kubeconfig \
      --region us-east-1 \
      --name eks-observability-cluster
```

Requires `eks:DescribeCluster` on the GitHub Actions IAM role. The role must also be mapped in `aws-auth` to a Kubernetes RBAC group — managed by Terraform in `terraform/apps/aws-auth.tf`.

### 5. Helm Deployment

```yaml
- name: Deploy FastAPI
  run: |
    helm upgrade --install fastapi-app ./helm/fastapi \
      --namespace default \
      --set image.repository=$ECR_REGISTRY/eks-observability-fastapi \
      --set image.tag=$IMAGE_TAG

- name: Deploy Website
  run: |
    helm upgrade --install website ./helm/website \
      --namespace default \
      --set image.repository=$ECR_REGISTRY/eks-observability-website \
      --set image.tag=$IMAGE_TAG
```

`helm upgrade --install` is idempotent — installs on first run, upgrades on subsequent runs. Kubernetes applies a rolling update by default, replacing pods incrementally with zero downtime.



## IAM Requirements

The GitHub Actions role requires the following permissions:

```json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["eks:DescribeCluster"],
      "Resource": "arn:aws:eks:us-east-1:<ACCOUNT_ID>:cluster/eks-observability-cluster"
    }
  ]
}
```

RBAC mapping in `aws-auth` (managed by Terraform):

```yaml
- rolearn: arn:aws:iam::<ACCOUNT_ID>:role/eks-observability-github-actions-role
  username: github-actions
  groups:
    - system:masters
```



## Triggering a Deployment

Push any commit to `main`:

```bash
git push origin main
```

To trigger without a code change:

```bash
git commit --allow-empty -m "trigger: redeploy"
git push origin main
```

Monitor the run under the **Actions** tab in the repository.



## Debugging Pipeline Failures

| Failure | Likely Cause | Check |
|---|---|---|
| OIDC authentication failed | Trust policy mismatch or missing `id-token: write` permission | Verify `role-to-assume` ARN and workflow permissions block |
| ECR push denied (403) | Node role missing ECR push permissions | Check IAM policy attached to GitHub Actions role |
| `helm: command not found` | Helm not installed on runner | Add `helm` installation step or use a custom runner image |
| `helm upgrade` failed — chart path not found | Incorrect path in workflow | Confirm path is relative to repo root: `./helm/fastapi` |
| `kubectl`: Unauthorized | `aws-auth` missing GitHub Actions role mapping | Check `kubectl describe configmap aws-auth -n kube-system` |
| Pods in `ImagePullBackOff` | Wrong image URI or missing ECR read permission on node role | Check `kubectl describe pod <pod> -n default` |

Always expand the full step log in the Actions UI — the meaningful error is typically several lines above the `Error:` summary line.

