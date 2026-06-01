# Implementation Challenges and Engineering Learnings

> Cloud-Native Observability Platform · Amazon EKS · BTech Major Project 2025–26

This document is a structured record of meaningful engineering challenges encountered during implementation. Entries are consolidated by root cause and component — near-duplicate issues have been merged into single authoritative records. Each entry reflects a real failure mode with a technical root cause and a concrete remediation.

---

## Table of Contents

1. [Terraform: Module Design & State Management](#1-terraform-module-design--state-management)
2. [Terraform: Provider Configuration & CLI Usage](#2-terraform-provider-configuration--cli-usage)
3. [Terraform: Dependency Ordering & Race Conditions](#3-terraform-dependency-ordering--race-conditions)
4. [Terraform: State Drift & Lifecycle Management](#4-terraform-state-drift--lifecycle-management)
5. [EKS: Authentication & RBAC](#5-eks-authentication--rbac)
6. [EKS: Node IAM & Image Pull Failures](#6-eks-node-iam--image-pull-failures)
7. [Kubernetes: Namespace & Label Management](#7-kubernetes-namespace--label-management)
8. [Kubernetes: Ingress Architecture & Cross-Namespace Routing](#8-kubernetes-ingress-architecture--cross-namespace-routing)
9. [Kubernetes: Ingress Conflicts & Path Routing](#9-kubernetes-ingress-conflicts--path-routing)
10. [Kubernetes: CRD Lifecycle (Prometheus Operator)](#10-kubernetes-crd-lifecycle-prometheus-operator)
11. [Kubernetes: Namespace Termination Stuck State](#11-kubernetes-namespace-termination-stuck-state)
12. [Helm: Release Management & Configuration](#12-helm-release-management--configuration)
13. [Observability: FastAPI Instrumentation](#13-observability-fastapi-instrumentation)
14. [Observability: Prometheus Service Discovery](#14-observability-prometheus-service-discovery)
15. [Observability: Grafana Dashboard Provisioning & Subpath Routing](#15-observability-grafana-dashboard-provisioning--subpath-routing)
16. [Observability: Alertmanager Configuration & Alert Pipeline](#16-observability-alertmanager-configuration--alert-pipeline)
17. [CI/CD: GitHub Actions Authentication (OIDC vs Static Keys)](#17-cicd-github-actions-authentication-oidc-vs-static-keys)
18. [CI/CD: Pipeline Image Management](#18-cicd-pipeline-image-management)
19. [CI/CD: Pipeline Failures & Debugging](#19-cicd-pipeline-failures--debugging)
20. [AWS: Infrastructure Teardown Order](#20-aws-infrastructure-teardown-order)
21. [Security: Hardcoded Credentials & Excessive Permissions](#21-security-hardcoded-credentials--excessive-permissions)
22. [Application Design: Repository Structure & Multi-Service Architecture](#22-application-design-repository-structure--multi-service-architecture)

---

## 1. Terraform: Module Design & State Management

### Cross-Module Resource Referencing

**Description:** The `apps` Terraform layer attempted to reference resources defined in the `infra` layer directly, causing execution failures.

**Root Cause:** Terraform modules are hermetically isolated. Cross-layer resource references must go through explicit output declarations and a remote state data source — there is no direct object reference mechanism between separate root modules.

**Remediation:**
1. Declare all shared values as outputs in the `infra` layer (`outputs.tf`).
2. In the `apps` layer, consume them via `terraform_remote_state`:

```hcl
# terraform/apps/remote-state.tf
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "eks-observability-tf-state-800309353239"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}

# Usage
node_role_arn = data.terraform_remote_state.infra.outputs.eks_node_role_arn
```

**Validation:**
```bash
# Confirm outputs are available from the infra layer
terraform -chdir=terraform/infra output

# Confirm remote state is readable from apps layer
terraform -chdir=terraform/apps init
terraform -chdir=terraform/apps plan
```

---

### IAM Resources Placed in Root Module

**Description:** IAM role definitions were co-located in the root module rather than in a dedicated module, creating maintenance and reuse issues.

**Root Cause:** Initial scaffolding placed all resources flat in root. As the project grew, this made dependency graphs harder to manage and prevented clean separation of concerns.

**Remediation:** Refactored IAM resources into `terraform/infra/modules/iam/`. The root module references the module and passes the OIDC provider ARN as an input variable:

```hcl
module "iam" {
  source                   = "./modules/iam"
  project_name             = var.project_name
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
}
```

---

### Duplicate Resource Definitions

**Description:** `terraform apply` failed with `resource already exists` errors due to the same resource being defined in multiple places.

**Root Cause:** During refactoring, resources were added to modules without removing the original root-level definitions.

**Remediation:** Audit for duplicate blocks, remove redundant definitions, and use `terraform state rm` / `terraform import` to reconcile state if needed:

```bash
# List all tracked resources
terraform state list

# Remove a resource from state (before re-importing under correct address)
terraform state rm aws_iam_role.example

# Re-import under the module address
terraform import module.iam.aws_iam_role.github_actions \
  eks-observability-github-actions-role
```

---

## 2. Terraform: Provider Configuration & CLI Usage

### Helm Provider Configuration Error

**Description:** `terraform init` or `terraform apply` failed with a provider configuration schema error for the Helm provider.

**Root Cause:** The `helm` provider block syntax changed between versions. Using the old nested `kubernetes {}` block format with the new provider version caused a schema mismatch.

**Remediation:** Update to the current syntax (Helm provider `>= 2.x`):

```hcl
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
```

Pin provider versions explicitly in `versions.tf` to prevent future drift:

```hcl
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}
```

---

### Misuse of `terraform validate`

**Description:** `terraform validate` was run with `-var` flags and failed, causing confusion about whether the configuration was broken.

**Root Cause:** `terraform validate` only checks configuration syntax and schema — it does not evaluate variable values or make API calls. It is not a substitute for `terraform plan`.

**Correct usage:**
```bash
# Syntax check only — no variable input needed or accepted
terraform validate

# Runtime evaluation — provide variables here
terraform plan -var-file="env.tfvars"
terraform apply -var-file="env.tfvars"
```

---

### EKS Cluster Not Found (Region Mismatch)

**Description:** The `apps` Terraform layer could not locate the EKS cluster despite it existing.

**Root Cause:** The `infra` layer was applied targeting `us-east-1`, but the `apps` layer provider was inadvertently configured to a different region.

**Remediation:** Standardize the AWS region across all layers. Avoid hardcoding — use a shared variable or environment variable:

```hcl
provider "aws" {
  region = var.aws_region  # default = "us-east-1"
}
```

**Validation:**
```bash
aws eks list-clusters --region us-east-1
```

---

### Terraform Module Missing `required_providers`

**Description:** Terraform produced warnings about undeclared providers in child modules, and in some cases provider injection failed.

**Root Cause:** Child modules that use `kubernetes` or `helm` providers must declare them in their own `versions.tf`. Without this, Terraform cannot guarantee correct provider version propagation.

**Remediation:** Add `required_providers` to each module that uses a provider:

```hcl
# terraform/apps/modules/observability/providers.tf
terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" }
    helm       = { source = "hashicorp/helm" }
  }
}
```

---

## 3. Terraform: Dependency Ordering & Race Conditions

### CRD-Dependent Resources Applied Before CRD Installation

**Description:** `ServiceMonitor` and `PrometheusRule` resources failed to apply with `no matches for kind` errors.

**Root Cause:** The Prometheus Operator CRDs (installed by `kube-prometheus-stack`) were not yet present in the cluster when Terraform attempted to create the `kubernetes_manifest` resources that depend on them. Terraform has no native awareness of CRD readiness.

**Remediation:** Use `depends_on` to enforce sequencing:

```hcl
resource "kubernetes_manifest" "fastapi_servicemonitor" {
  # ...
  depends_on = [helm_release.kube_prometheus_stack]
}
```

**Validation:**
```bash
# Confirm CRDs are installed before applying dependent resources
kubectl get crd | grep monitoring.coreos.com
```

---

### Apps Layer Applied Before Cluster Was Ready

**Description:** Resources like the `aws-auth` ConfigMap and Helm releases failed during initial provisioning because the EKS cluster control plane was not yet accepting API requests.

**Root Cause:** The `apps` layer was applied immediately after the `infra` layer returned, but EKS cluster readiness lags behind Terraform's `apply` completion — the control plane endpoint may not be responsive for 1–3 minutes post-creation.

**Remediation:** Enforce staged deployment and confirm cluster readiness before proceeding:

```bash
# Stage 1 — provision infrastructure
terraform -chdir=terraform/infra apply

# Wait for cluster to become active
aws eks wait cluster-active --name eks-observability-cluster --region us-east-1

# Update local kubeconfig
aws eks update-kubeconfig --name eks-observability-cluster --region us-east-1

# Confirm API server is responsive
kubectl get nodes

# Stage 2 — deploy applications and observability stack
terraform -chdir=terraform/apps apply
```

---

### Terraform Destroy Fails Due to Dependency Order

**Description:** `terraform destroy` on the `infra` layer failed because the `apps` layer still held references to infra outputs (cluster name, VPC IDs).

**Root Cause:** The two-layer architecture requires reverse-order teardown. Destroying `infra` first removes cluster endpoints and networking that `apps` resources depend on, leaving Terraform unable to cleanly remove those resources.

**Remediation:** Always destroy in reverse provisioning order:

```bash
# Step 1 — destroy app-layer resources first
# Delete Kubernetes Ingress and LoadBalancer-type Services before running destroy,
# to allow AWS to release the ELB and ENI attachments
kubectl delete ingress --all -n default
kubectl delete ingress --all -n monitoring
kubectl delete svc --field-selector spec.type=LoadBalancer -A

# Step 2 — destroy apps Terraform layer
terraform -chdir=terraform/apps destroy

# Step 3 — destroy infra Terraform layer
terraform -chdir=terraform/infra destroy
```

---

## 4. Terraform: State Drift & Lifecycle Management

### "Resource Already Exists" After Manual Changes

**Description:** `terraform apply` failed with `AlreadyExists` errors for resources that were created manually outside Terraform.

**Root Cause:** Terraform state did not track manually created resources. Any resource created via `kubectl apply` or AWS Console without a corresponding `terraform import` is invisible to Terraform but still exists in the cluster/cloud.

**Remediation:**
```bash
# Import existing resource into state
terraform import kubernetes_config_map_v1_data.aws_auth kube-system/aws-auth

# Or remove stale state entry and re-apply cleanly
terraform state rm kubernetes_config_map_v1_data.aws_auth
terraform apply
```

**Policy:** After this incident, all cluster resources were managed exclusively through Terraform to prevent future drift.

---

### Partial Import Causing State Corruption

**Description:** A failed `terraform import` left the resource partially tracked, causing both `plan` and subsequent `import` attempts to fail.

**Root Cause:** If `terraform import` succeeds in writing to state but the configuration block does not match the imported resource's actual attributes, the state becomes inconsistent.

**Remediation:**
```bash
# Remove the corrupted state entry
terraform state rm <resource_address>

# Re-import cleanly after verifying the configuration block matches
terraform import <resource_address> <resource_id>

# Validate state is consistent
terraform plan  # should show no changes if config matches reality
```

---

### ECR Repository Deletion Blocked

**Description:** `terraform destroy` failed to delete the ECR repository because it still contained images.

**Root Cause:** AWS refuses to delete non-empty ECR repositories unless `force_delete` is enabled or images are removed first.

**Remediation:** Set `force_delete = true` in the ECR resource definition for non-production repositories:

```hcl
resource "aws_ecr_repository" "fastapi" {
  name         = "${var.project_name}-fastapi"
  force_delete = true
}
```

Or manually delete images before destroy:
```bash
aws ecr list-images --repository-name eks-observability-fastapi \
  --query 'imageIds[*]' --output json | \
  xargs -I {} aws ecr batch-delete-image \
    --repository-name eks-observability-fastapi \
    --image-ids {}
```

---

## 5. EKS: Authentication & RBAC

### IAM Roles Not Mapped in `aws-auth` ConfigMap

**Description:** The EKS cluster rejected requests from IAM roles used by worker nodes, the bastion host, and the GitHub Actions CI/CD pipeline. All three principals failed with `Unauthorized` errors despite having valid IAM credentials.

**Root Cause:** EKS uses the `aws-auth` ConfigMap (in `kube-system`) to map AWS IAM principals to Kubernetes RBAC groups. Without entries for each IAM role, the Kubernetes API server has no knowledge of those principals — IAM credentials alone are insufficient for cluster access.

**Remediation:** Manage `aws-auth` via Terraform to prevent manual drift:

```hcl
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true
  data = {
    mapRoles = yamlencode([
      {
        rolearn  = data.terraform_remote_state.infra.outputs.eks_node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = data.terraform_remote_state.infra.outputs.bastion_role_arn
        username = "bastion"
        groups   = ["system:masters"]
      },
      {
        rolearn  = "arn:aws:iam::ACCOUNT_ID:role/eks-observability-github-actions-role"
        username = "github-actions"
        groups   = ["system:masters"]
      }
    ])
  }
}
```

**Validation:**
```bash
# Confirm the ConfigMap contains all required role mappings
kubectl describe configmap aws-auth -n kube-system

# Test cluster access using a specific IAM role
aws sts assume-role --role-arn <role_arn> --role-session-name test
aws eks get-token --cluster-name eks-observability-cluster
kubectl get nodes
```

---

### GitHub Actions Pipeline Could Not Access Cluster

**Description:** The CI/CD pipeline failed during `helm upgrade` with `error: You must be logged in to the server (Unauthorized)`.

**Root Cause:** Two compounding issues: (1) the GitHub Actions IAM role lacked `eks:DescribeCluster` permission required by `aws eks update-kubeconfig`, and (2) the role was not mapped in `aws-auth`.

**Remediation:**

Add `eks:DescribeCluster` to the GitHub Actions IAM role policy:

```hcl
resource "aws_iam_role_policy" "github_actions_describe_cluster" {
  name = "github-actions-describe-cluster"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "arn:aws:eks:us-east-1:ACCOUNT_ID:cluster/eks-observability-cluster"
    }]
  })
}
```

In the workflow, update kubeconfig before any Helm commands:
```yaml
- name: Update kubeconfig
  run: |
    aws eks update-kubeconfig \
      --region $AWS_REGION \
      --name eks-observability-cluster
```

**Validation:**
```bash
# From the GitHub Actions runner context
aws sts get-caller-identity
aws eks update-kubeconfig --name eks-observability-cluster --region us-east-1
kubectl get nodes
```

---

## 6. EKS: Node IAM & Image Pull Failures

### Pods Failing with `ImagePullBackOff` / 403 Errors from ECR

**Description:** Pod startup failed consistently with `ImagePullBackOff`. Kubernetes events showed `failed to pull image: 403 Forbidden` from the ECR registry.

**Root Cause:** EKS worker nodes pull images from ECR using the node IAM role. If `AmazonEC2ContainerRegistryReadOnly` is not attached to that role, the ECR API returns 403. A secondary cause in this project was an incorrect ECR URI (wrong account ID or region) specified in the Helm chart.

**Remediation:**

Attach the required policy to the node role in Terraform:

```hcl
resource "aws_iam_role_policy_attachment" "eks_node_ecr" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

Use dynamic ECR URIs in Helm deployments — never hardcode account IDs:

```yaml
# GitHub Actions workflow
helm upgrade --install fastapi-app ./helm/fastapi \
  --set image.repository=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/eks-observability-fastapi \
  --set image.tag=$IMAGE_TAG
```

**Validation:**
```bash
# Describe a failing pod to see the exact error
kubectl describe pod <pod-name> -n default

# Confirm node role has ECR read access
aws iam list-attached-role-policies \
  --role-name eks-observability-eks-node-role

# Manually test image pull from ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker pull ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/eks-observability-fastapi:TAG
```

---

## 7. Kubernetes: Namespace & Label Management

### Label Mismatch Breaking Service Discovery

**Description:** `ServiceMonitor` failed to bind to the FastAPI service. Prometheus showed no targets for the FastAPI scrape job despite the `ServiceMonitor` existing.

**Root Cause:** Kubernetes label selectors are case-sensitive. A case inconsistency (`App: FastAPI` in the Deployment vs. `app: fastapi` in the `ServiceMonitor` selector) caused a zero-match condition. No error is surfaced — the selector simply matches nothing.

**Remediation:** Standardize all label definitions across `Deployment`, `Service`, and `ServiceMonitor` manifests. Use lowercase values consistently:

```yaml
# Deployment
labels:
  app: fastapi

# Service
selector:
  app: fastapi

# ServiceMonitor
selector:
  matchLabels:
    app: fastapi
namespaceSelector:
  matchNames:
    - default
```

**Validation:**
```bash
# Confirm label values on the service
kubectl get svc fastapi-app -n default --show-labels

# Confirm ServiceMonitor selector matches
kubectl get servicemonitor fastapi -n monitoring -o yaml

# Check Prometheus targets (should show fastapi endpoints)
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090 -n monitoring
# Then open: http://localhost:9090/targets
```

---

### Namespace Inconsistency Across Components

**Description:** Components deployed in different namespaces caused service discovery failures and debugging confusion.

**Root Cause:** During initial development, namespace assignments were not documented, leading to some FastAPI components landing in `default` and monitoring resources inconsistently placed between `default` and `monitoring`.

**Remediation:** Enforce a documented namespace topology:

| Component | Namespace |
|---|---|
| FastAPI, Website | `default` |
| Prometheus, Grafana, Alertmanager, Blackbox Exporter | `monitoring` |
| NGINX Ingress Controller | `ingress-nginx` |

All Helm chart `values.yaml` files and Terraform resources should reference these namespaces explicitly.

**Validation:**
```bash
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
```

---

## 8. Kubernetes: Ingress Architecture & Cross-Namespace Routing

### 503 Errors Accessing Observability Tools via Ingress

**Description:** Requests to `/grafana`, `/prometheus`, and `/alertmanager` via the NGINX Ingress returned 503 errors.

**Root Cause:** The `Ingress` resource was created in the `default` namespace, but the backing services (`kube-prometheus-stack-grafana`, etc.) live in the `monitoring` namespace. Kubernetes `Ingress` is namespace-scoped — it cannot directly reference a `Service` in another namespace.

**Remediation:** Create `ExternalName` services in the `default` namespace to proxy traffic across namespaces:

```hcl
resource "kubernetes_service_v1" "grafana_proxy" {
  metadata {
    name      = "grafana-proxy"
    namespace = "default"
  }
  spec {
    type          = "ExternalName"
    external_name = "kube-prometheus-stack-grafana.monitoring.svc.cluster.local"
    port { port = 80 }
  }
}
```

The `Ingress` in `default` then routes to `grafana-proxy`, which resolves to the `monitoring` namespace service via DNS.

**Validation:**
```bash
# Confirm ExternalName service resolves correctly from within the cluster
kubectl run debug --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v http://grafana-proxy.default.svc.cluster.local/grafana

# Check ingress is receiving the external IP
kubectl get ingress -n default
```

---

### Ingress Controller Not Restored After Infrastructure Recreation

**Description:** After `terraform destroy` and re-apply, the NGINX Ingress Controller was missing and all HTTP traffic was broken.

**Root Cause:** The Ingress Controller was originally installed manually via `kubectl apply`. Since Terraform had no record of it, destroy/apply cycles did not recreate it.

**Remediation:** Manage the Ingress Controller as a Terraform `helm_release` resource:

```hcl
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  set = [{
    name  = "controller.service.type"
    value = "LoadBalancer"
  }]
}
```

**Validation:**
```bash
kubectl get svc -n ingress-nginx
# Expect: nginx-ingress-controller with EXTERNAL-IP assigned
```

---

## 9. Kubernetes: Ingress Conflicts & Path Routing

### Duplicate Route Definitions and 503/404 Errors After Redeployment

**Description:** After redeployments, NGINX reported duplicate path conflicts and some services returned 404 or 503. This manifested in several forms: duplicate ingress resources with the same path, stale ingress objects left from previous deployments, and incorrect path rewrites.

**Root Cause (consolidated):**
- Multiple `Ingress` objects across namespaces defined overlapping paths.
- Static ingress names caused resource conflicts when Helm re-released with a different release name.
- A global `nginx.ingress.kubernetes.io/rewrite-target: /$2` annotation was applied to all routes including Grafana and Prometheus, which do not expect URL rewriting and broke their UIs.

**Remediation:**

Use dynamic ingress names from Helm release names to prevent conflicts:
```yaml
# helm/fastapi/templates/ingress.yaml
metadata:
  name: {{ .Release.Name }}-ingress
```

Apply rewrite annotations only to routes that require them (e.g., the FastAPI API path), not to observability tool routes:
```yaml
# Ingress for API (needs rewrite)
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2
paths:
  - path: /api(/|$)(.*)

# Separate ingress for Grafana (no rewrite)
paths:
  - path: /grafana
    pathType: Prefix
```

Before redeployment, clean up stale ingress resources:
```bash
kubectl delete ingress --all -n default
kubectl delete ingress --all -n monitoring
```

**Validation:**
```bash
# Confirm no duplicate path definitions
kubectl get ingress -A

# Test each route
curl -v http://<EXTERNAL_IP>/
curl -v http://<EXTERNAL_IP>/api/
curl -v http://<EXTERNAL_IP>/grafana
curl -v http://<EXTERNAL_IP>/prometheus
curl -v http://<EXTERNAL_IP>/alertmanager
```

---

### Grafana Redirect Loop and Prometheus 404 via Ingress

**Description:** Accessing `/grafana` caused an infinite redirect loop. Accessing `/prometheus` returned 404 from the Prometheus UI.

**Root Cause:** Both Grafana and Prometheus were unaware they were being served from a subpath. Without explicit subpath configuration, they generated absolute redirect URLs and asset paths that did not include the ingress prefix, breaking navigation.

**Remediation:**

For Grafana, set `root_url` and enable `serve_from_sub_path`:
```hcl
"grafana.ini" = {
  server = {
    root_url            = "http://<LB_HOSTNAME>/grafana"
    serve_from_sub_path = true
  }
}
```

For Prometheus, set `externalUrl` and `routePrefix`:
```hcl
prometheusSpec = {
  externalUrl  = "http://<LB_HOSTNAME>/prometheus"
  routePrefix  = "/prometheus"
}
```

For Alertmanager, apply a regex rewrite so internal asset requests resolve correctly:
```yaml
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2
path: /alertmanager(/|$)(.*)
pathType: ImplementationSpecific
```

**Validation:**
```bash
# Verify Grafana is accessible without redirect loop
curl -L http://<LB_HOSTNAME>/grafana/login

# Verify Prometheus UI loads
curl http://<LB_HOSTNAME>/prometheus/graph
```

---

## 10. Kubernetes: CRD Lifecycle (Prometheus Operator)

### CRD Resources Fail on Apply and Destroy

**Description:** On initial apply, `ServiceMonitor` and `PrometheusRule` manifests returned `no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"`. On teardown, deleting the `kube-prometheus-stack` Helm release before removing `PrometheusRule` resources caused orphaned finalizers.

**Root Cause:** The Prometheus Operator registers its CRDs (`ServiceMonitor`, `PrometheusRule`, `Probe`, etc.) as part of the Helm chart installation. Any `kubernetes_manifest` resource that uses these kinds must be applied after the CRDs exist and removed before the CRDs are deleted.

**Remediation:**

Apply: use `depends_on` for all CRD-dependent resources:
```hcl
resource "kubernetes_manifest" "fastapi_servicemonitor" {
  depends_on = [helm_release.kube_prometheus_stack]
  # ...
}
```

Destroy: delete CRD-dependent resources before the Helm release:
```bash
kubectl delete servicemonitor --all -n monitoring
kubectl delete prometheusrule --all -n monitoring
kubectl delete probe --all -n monitoring

terraform -chdir=terraform/apps destroy
```

**Validation:**
```bash
# Confirm all Prometheus Operator CRDs are present
kubectl get crd | grep monitoring.coreos.com

# Expected output includes:
# alertmanagers.monitoring.coreos.com
# prometheuses.monitoring.coreos.com
# prometheusrules.monitoring.coreos.com
# servicemonitors.monitoring.coreos.com
# probes.monitoring.coreos.com
```

---

## 11. Kubernetes: Namespace Termination Stuck State

**Description:** The `monitoring` namespace was stuck in `Terminating` state and could not be removed.

**Root Cause:** Kubernetes namespaces with finalizers will not complete deletion until all resources with finalizers inside them are removed. CRD-backed resources (like `ServiceMonitor`) that have finalizers set by the Prometheus Operator will block namespace termination if the operator is no longer running to process the finalizer removal.

**Remediation:**
```bash
# List all resources still present in the stuck namespace
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -I {} kubectl get {} -n monitoring --ignore-not-found

# Force-remove finalizers from stuck resources
kubectl patch servicemonitor fastapi -n monitoring \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# As a last resort — patch the namespace itself to remove its finalizer
kubectl get namespace monitoring -o json | \
  jq '.spec.finalizers=[]' | \
  kubectl replace --raw "/api/v1/namespaces/monitoring/finalize" -f -
```

---

## 12. Helm: Release Management & Configuration

### Helm Release Stuck in Failed State

**Description:** `helm upgrade --install` failed with `cannot re-use a name that is still in use` or a release remained in `failed` state after a partial deployment.

**Root Cause:** A previous deployment failure left Helm metadata (stored as Kubernetes Secrets in the release namespace) in a `failed` or `pending-upgrade` state. Subsequent `helm upgrade` commands interpreted the release as locked.

**Remediation:**
```bash
# Inspect the release state
helm status fastapi-app -n default
helm history fastapi-app -n default

# Roll back to the last successful revision
helm rollback fastapi-app -n default

# If rollback is not possible, uninstall and redeploy
helm uninstall fastapi-app -n default
helm upgrade --install fastapi-app ./helm/fastapi \
  --namespace default \
  --set image.repository=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/eks-observability-fastapi \
  --set image.tag=$IMAGE_TAG
```

---

### Helm Chart Path Not Found

**Description:** Terraform `helm_release` failed with `path does not exist` for local chart references. GitHub Actions pipeline failed with `Error: no such file or directory: ./helm/fastapi`.

**Root Cause:** Relative paths in Helm are resolved relative to the working directory at execution time. Both the Terraform execution directory and the GitHub Actions `run` working directory must be considered when specifying chart paths.

**Remediation:**

In GitHub Actions, paths are relative to the repository root:
```yaml
- name: Deploy FastAPI
  run: |
    helm upgrade --install fastapi-app ./helm/fastapi \
      --set image.tag=${{ env.IMAGE_TAG }}
```

In Terraform `helm_release` with a local chart:
```hcl
resource "helm_release" "fastapi" {
  chart = "${path.root}/../../helm/fastapi"
}
```

**Validation:**
```bash
# Confirm chart structure from repo root
ls helm/fastapi/
# Expected: Chart.yaml  templates/  values.yaml

helm lint ./helm/fastapi
```

---

### YAML Errors in Helm Values

**Description:** Helm deployments produced unexpected behavior or failed with template rendering errors despite values appearing correct in the editor.

**Root Cause:** YAML is whitespace-sensitive. Incorrect indentation, unquoted strings containing special characters, and missing required keys all result in either silent misconfiguration or rendering failures.

**Remediation:**
```bash
# Lint the chart before deploying
helm lint ./helm/fastapi

# Render templates locally to inspect output before applying
helm template fastapi-app ./helm/fastapi \
  --set image.repository=REPO \
  --set image.tag=TAG

# Diff against the current release to see what would change
helm diff upgrade fastapi-app ./helm/fastapi \
  --set image.tag=NEW_TAG
```

---

## 13. Observability: FastAPI Instrumentation

### FastAPI Missing `/metrics` and `/health` Endpoints

**Description:** Prometheus reported `connection refused` when scraping the FastAPI pod. Kubernetes readiness probes were failing, causing pods to be removed from service rotation.

**Root Cause:** The base FastAPI application had no Prometheus metrics endpoint and no health check route. The `prometheus-fastapi-instrumentator` library must be explicitly added and initialized.

**Remediation:**

Add to `requirements.txt`:
```
fastapi
uvicorn
prometheus-fastapi-instrumentator
```

Instrument in `main.py`:
```python
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

Instrumentator().instrument(app).expose(app)
# This registers the /metrics endpoint automatically
```

**Validation:**
```bash
# Port-forward to the pod and confirm endpoints
kubectl port-forward deployment/fastapi-app 8000:8000 -n default

curl http://localhost:8000/health
# Expected: {"status":"ok"}

curl http://localhost:8000/metrics
# Expected: Prometheus text format output
```

---

## 14. Observability: Prometheus Service Discovery

### Prometheus Not Scraping FastAPI Targets

**Description:** The Prometheus targets page showed no entry for FastAPI. The `ServiceMonitor` existed but Prometheus had not discovered the target.

**Root Cause:** Two compounding issues: (1) the `ServiceMonitor`'s `namespaceSelector` did not include `default` (where FastAPI runs), and (2) the `ServiceMonitor` label `release: kube-prometheus-stack` must match the Prometheus Operator's `serviceMonitorSelector` configuration.

**Remediation:**

Correct `ServiceMonitor` definition:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: fastapi
  namespace: monitoring
  labels:
    release: kube-prometheus-stack   # must match Prometheus serviceMonitorSelector
spec:
  selector:
    matchLabels:
      app: fastapi
  namespaceSelector:
    matchNames:
      - default                        # namespace where FastAPI Service lives
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

**Validation:**
```bash
# Check Prometheus has picked up the ServiceMonitor
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090 -n monitoring

# Open: http://localhost:9090/targets
# Expect: fastapi/0 endpoint listed as UP

# Check for scrape errors
# Open: http://localhost:9090/config
# Confirm fastapi scrape job is present
```

---

## 15. Observability: Grafana Dashboard Provisioning & Subpath Routing

### Dashboards Not Loading After Deployment

**Description:** After deploying Grafana, no custom dashboards were visible in the UI.

**Root Cause:** Grafana's sidecar dashboard provisioner discovers dashboards from ConfigMaps labeled `grafana_dashboard: "1"`. Without this label, the sidecar ignores the ConfigMap. Additionally, the dashboard provider configuration must declare the target folder path.

**Remediation:**

Create the dashboard ConfigMap with the required label:
```hcl
resource "kubernetes_config_map_v1" "grafana_fastapi_dashboard" {
  metadata {
    name      = "grafana-fastapi-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"    # required for sidecar discovery
    }
  }
  data = {
    "fastapi-golden-signals.json" = file("${path.module}/grafana/dashboards/fastapi-golden-signals.json")
  }
}
```

Enable the sidecar in the Helm values:
```hcl
grafana = {
  sidecar = {
    dashboards = {
      enabled         = true
      label           = "grafana_dashboard"
      searchNamespace = "ALL"
    }
  }
}
```

**Validation:**
```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
# Open: http://localhost:3000/dashboards
# Expect: "FastAPI — Golden Signals" dashboard visible
```

---

## 16. Observability: Alertmanager Configuration & Alert Pipeline

### Alertmanager Pods Not Starting

**Description:** The Alertmanager StatefulSet had zero running pods. The service existed but was inaccessible.

**Root Cause:** The Alertmanager Operator validates configuration before creating the StatefulSet. A malformed configuration (specifically, a missing `null` receiver referenced in the default route) caused the operator to reject the configuration and never create the pods.

**Remediation:** Ensure the `null` receiver is explicitly declared even if unused:

```hcl
alertmanager = {
  config = {
    route = {
      receiver       = "email-notifications"
      group_by       = ["alertname"]
      group_wait     = "10s"
      group_interval = "1m"
      repeat_interval = "1h"
    }
    receivers = [
      { name = "null" },          # required even if not used in routing
      {
        name = "email-notifications"
        email_configs = [{
          to            = "ops@example.com"
          send_resolved = true
        }]
      }
    ]
  }
}
```

**Validation:**
```bash
# Check operator logs for config validation errors
kubectl logs -l app.kubernetes.io/name=alertmanager-operator -n monitoring

# Confirm pods are running
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

# Inspect generated config
kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -n monitoring \
  -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
```

---

### Alerts Not Forwarded from Prometheus to Alertmanager

**Description:** Alert rules were evaluating correctly in Prometheus (visible in `/alerts`), but Alertmanager received nothing.

**Root Cause:** Two issues were found: (1) the Prometheus `alertingEndpoints` configuration referenced the wrong service port name (`http` instead of `http-web`), causing Prometheus to fail to connect to Alertmanager; and (2) an incorrect `127.0.0.1` webhook endpoint was used in earlier testing, which resolves to the container itself rather than an external service.

**Remediation:**

Correct the alerting endpoint in `prometheusSpec`:
```hcl
prometheusSpec = {
  alertingEndpoints = [{
    name      = "kube-prometheus-stack-alertmanager"
    namespace = "monitoring"
    port      = "http-web"    # must match the service port name
  }]
}
```

**Validation:**
```bash
# Confirm Prometheus is connected to Alertmanager
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090 -n monitoring
# Open: http://localhost:9090/status
# Under "Alertmanagers": should show alertmanager endpoint as active

# Check Alertmanager is receiving alerts
kubectl port-forward svc/kube-prometheus-stack-alertmanager 9093 -n monitoring
# Open: http://localhost:9093/#/alerts

# Simulate a failure to trigger an alert end-to-end
kubectl scale deployment fastapi-app --replicas=0 -n default
# Wait 30s for FastAPIDown alert to fire
# Confirm alert appears in Alertmanager UI and email is received
kubectl scale deployment fastapi-app --replicas=2 -n default
```

---

### Silent Alert Delivery Failure (Email)

**Description:** Alerts were visible in Alertmanager but email notifications were not received. No errors were surfaced in Alertmanager logs.

**Root Cause:** The Gmail SMTP credentials (App Password) were incorrect or the SMTP configuration was using placeholder values.

**Remediation:** Configure valid Gmail SMTP with an App Password (not the account password):

```hcl
global = {
  smtp_smarthost     = "smtp.gmail.com:587"
  smtp_from          = "sender@gmail.com"
  smtp_auth_username = "sender@gmail.com"
  smtp_auth_password = "<16-char-app-password>"  # from Google Account > Security > App Passwords
  smtp_require_tls   = true
}
```

**Validation:**
```bash
# Use amtool to test Alertmanager config and fire a test alert
kubectl exec -it alertmanager-kube-prometheus-stack-alertmanager-0 -n monitoring -- \
  amtool check-config /etc/alertmanager/config_out/alertmanager.env.yaml

# Send a test alert manually
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestAlert","severity":"critical"}}]'
```

---

## 17. CI/CD: GitHub Actions Authentication (OIDC vs Static Keys)

### Secure AWS Authentication Without Static Credentials

**Description:** The CI/CD pipeline required AWS access to push images to ECR and deploy to EKS. Hardcoding `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub secrets is a security anti-pattern and creates long-lived credential exposure risk.

**Root Cause:** The initial approach used static IAM user credentials. The correct approach for GitHub Actions is OIDC federation — GitHub issues a short-lived OIDC token per workflow run, which AWS exchanges for temporary STS credentials.

**Remediation:**

Provision the OIDC provider in Terraform:
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

Create a role with a trust policy scoped to the specific repository:
```hcl
Condition = {
  StringLike = {
    "token.actions.githubusercontent.com:sub" =
      "repo:org/repo-name:*"
  }
}
```

In the workflow:
```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT_ID:role/eks-observability-github-actions-role
    aws-region: us-east-1
```

**Validation:**
```bash
# In the pipeline, confirm the assumed identity
aws sts get-caller-identity
# Expected: ARN of the GitHub Actions role, not a user
```

---

## 18. CI/CD: Pipeline Image Management

### Non-Deterministic Deployments Due to `latest` Tag

**Description:** Deployments to the cluster were inconsistent — pods sometimes ran older image versions after redeploy.

**Root Cause:** Container images tagged `latest` are mutable. With `imagePullPolicy: IfNotPresent`, the kubelet does not re-pull an image if a layer with that tag is already present on the node, even if the registry has a newer version.

**Remediation:** Tag all production images with the git commit SHA. The GitHub Actions workflow uses `${{ github.sha }}` for this:

```yaml
env:
  IMAGE_TAG: ${{ github.sha }}

- name: Tag and push
  run: |
    docker tag fastapi-app:latest \
      $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/eks-observability-fastapi:$IMAGE_TAG
    docker push \
      $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/eks-observability-fastapi:$IMAGE_TAG
```

```yaml
# In Helm values or --set flag
image:
  tag: ""        # always overridden by --set image.tag=$IMAGE_TAG in CI
  pullPolicy: Always
```

---

### ECR Authentication Failure During Image Push

**Description:** `docker push` to ECR returned `no basic auth credentials` or `denied: Your authorization token has expired`.

**Root Cause:** Docker requires an authentication token before pushing to ECR. This token is short-lived (12 hours) and must be refreshed before each CI run.

**Remediation:** Use the `amazon-ecr-login` action in GitHub Actions, which handles authentication automatically:

```yaml
- name: Login to ECR
  uses: aws-actions/amazon-ecr-login@v2
```

For local development:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS \
  --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

---

## 19. CI/CD: Pipeline Failures & Debugging

### Debugging Failed Pipeline Runs

**Description:** Pipeline failures were difficult to diagnose because logs were not examined thoroughly and failure messages were generic.

**Root Cause:** GitHub Actions surfaces the first non-zero exit code but the meaningful error is often several lines above in the step output. Insufficient log review led to misdiagnosis.

**Operational practices established:**

- Always expand the full step log in the GitHub Actions UI, not just the summary.
- Add explicit debug commands before critical steps:

```yaml
- name: Debug context
  run: |
    aws sts get-caller-identity
    kubectl config current-context
    kubectl get nodes
    helm list -A
```

- Use `set -euxo pipefail` in multi-line shell scripts to surface the exact failing command:

```yaml
- name: Deploy
  run: |
    set -euxo pipefail
    helm upgrade --install fastapi-app ./helm/fastapi \
      --set image.tag=$IMAGE_TAG
```

---

### Bash Variable Expansion Errors in Automation Scripts

**Description:** Shell automation scripts failed unexpectedly when executed in CI, with errors like `bad substitution` or unexpected variable expansion.

**Root Cause:** Heredoc blocks in scripts (`<< EOF`) perform variable substitution by default. AWS CLI commands embedded in heredocs that contain `${}` syntax were being interpreted by the shell rather than passed as literals.

**Remediation:** Use a quoted heredoc to prevent expansion:

```bash
# ❌ Variables expanded by shell — breaks AWS CLI JSON payloads
cat << EOF
  { "roleArn": "${ROLE_ARN}" }
EOF

# ✅ Quoted heredoc — no expansion
cat << 'EOF'
  { "roleArn": "${ROLE_ARN}" }
EOF
```

---

## 20. AWS: Infrastructure Teardown Order

### ELB and ENI Blocking Subnet/VPC Deletion

**Description:** `terraform destroy` on the `infra` layer failed with errors like `DependencyViolation: The subnet has dependencies and cannot be deleted`.

**Root Cause:** When a Kubernetes `Service` of type `LoadBalancer` is created, AWS provisions an Elastic Load Balancer and attaches Elastic Network Interfaces to the cluster subnets. These resources are managed by the Kubernetes AWS cloud controller — not Terraform. If they exist when Terraform attempts to delete the subnets, AWS refuses the deletion.

**Remediation:** Delete all Kubernetes resources that cause AWS resource provisioning before running `terraform destroy`:

```bash
# Delete all LoadBalancer-type Services (releases ELBs)
kubectl delete svc --field-selector spec.type=LoadBalancer -A

# Delete all Ingress objects (releases ELBs created by ingress controller)
kubectl delete ingress --all -A

# Wait for AWS to release the ELB and ENIs (typically 30–60 seconds)
sleep 60

# Confirm no ELBs remain associated with the cluster VPC
aws elb describe-load-balancers \
  --query 'LoadBalancerDescriptions[?VPCId==`<vpc-id>`]'

# Then destroy apps layer, then infra
terraform -chdir=terraform/apps destroy
terraform -chdir=terraform/infra destroy
```

---

### Internet Gateway Cannot Detach

**Description:** VPC deletion during `terraform destroy` failed because the Internet Gateway could not be detached.

**Root Cause:** Active public IP mappings (Elastic IPs) or ELB dependencies kept the IGW attached. The IGW cannot be detached from a VPC that has active routing dependencies.

**Remediation:** Ensure all public-facing resources (ELBs, NAT Gateway EIPs) are removed before the IGW:

```bash
# Release the NAT Gateway EIP
aws ec2 release-address --allocation-id <eip-allocation-id>

# Confirm no active ELBs in the VPC
aws elb describe-load-balancers

# Then re-run destroy
terraform -chdir=terraform/infra destroy
```

---

## 21. Security: Hardcoded Credentials & Excessive Permissions

### SMTP Credentials and Grafana Password in Source Code

**Description:** Gmail SMTP App Password and Grafana admin password were committed in plaintext inside Terraform HCL files.

**Root Cause:** Credentials were placed directly in `helm-kube-prometheus.tf` as inline `yamlencode` values for initial convenience and were not moved to secure storage.

**Remediation (planned):** Externalize secrets using Kubernetes Secrets or AWS Secrets Manager:

```bash
# Create a Kubernetes Secret for Alertmanager SMTP credentials
kubectl create secret generic alertmanager-smtp \
  --from-literal=smtp_password=<app-password> \
  -n monitoring
```

Reference the secret in the Alertmanager configuration rather than embedding the value in Helm values. At minimum, use Terraform input variables marked `sensitive`:

```hcl
variable "smtp_password" {
  type      = string
  sensitive = true
}
```

> **Note:** The SMTP App Password visible in this repository's source files should be rotated immediately.

---

### Bastion Host SSH Open to `0.0.0.0/0`

**Description:** The bastion host security group allowed inbound SSH from any IP, and its IAM role was mapped to `system:masters`.

**Root Cause:** The security group used `cidr_blocks = ["0.0.0.0/0"]` for port 22, and the RBAC mapping granted full cluster admin access rather than a least-privilege role.

**Remediation:**

Restrict SSH to known IPs:
```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["<your-office-ip>/32"]
}
```

Replace `system:masters` with a scoped role, or migrate entirely to AWS Systems Manager Session Manager (no port 22 required):

```hcl
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

---

## 22. Application Design: Repository Structure & Multi-Service Architecture

### Deploying Multiple Services from a Single Pipeline

**Description:** The initial GitHub Actions workflow only built and deployed the FastAPI image. When the website service was added, the pipeline had to be extended.

**Root Cause:** The initial design assumed a single application. Multi-service pipelines require separate build/tag/push/deploy steps per image.

**Remediation:** Extend the workflow with explicit per-service jobs:

```yaml
# Build and push both images
- name: Build FastAPI image
  run: docker build -t fastapi-app ./apps/fastapi

- name: Build Website image
  run: docker build -t website ./apps/website

# Deploy both via Helm
- name: Deploy FastAPI
  run: |
    helm upgrade --install fastapi-app ./helm/fastapi \
      --set image.repository=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/eks-observability-fastapi \
      --set image.tag=$IMAGE_TAG

- name: Deploy Website
  run: |
    helm upgrade --install website ./helm/website \
      --set image.repository=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/eks-observability-website \
      --set image.tag=$IMAGE_TAG
```

---

### Non-Reproducible Deployments from Mixed Management Approaches

**Description:** The same deployment sequence produced different cluster states across runs.

**Root Cause:** A combination of `kubectl apply`, manual Helm CLI commands, and Terraform `helm_release` resources were all managing overlapping resources. There was no single source of truth.

**Remediation:** Enforce a strict management boundary:

| Resource | Manager |
|---|---|
| AWS infrastructure (VPC, EKS, ECR, IAM) | Terraform (`infra` layer) |
| Observability stack (kube-prometheus-stack, Blackbox Exporter) | Terraform (`apps` layer, `helm_release`) |
| Application workloads (FastAPI, Website) | GitHub Actions CI/CD (`helm upgrade --install`) |
| `aws-auth` ConfigMap | Terraform (`apps` layer, `kubernetes_config_map_v1_data`) |

No resource should be managed by more than one tool.

---

*Document version: 1.0 · Last updated: 2025–26 academic cycle*
*Related: `docs/architecture.md` · `README.md` · `helm/` · `terraform/`*
