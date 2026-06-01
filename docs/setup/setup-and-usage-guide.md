# Setup & Operations Guide

Cloud-Native Observability Platform · Amazon EKS · Terraform · GitHub Actions

> **Cost warning:** This project provisions billable AWS infrastructure (EKS control plane ~$0.10/hr, EC2 nodes, NAT Gateway, ELB). Run only for active testing and destroy immediately after. See [Teardown](#4-teardown) before starting.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Provisioning](#2-provisioning)
3. [Verification & Validation](#3-verification--validation)
4. [Teardown](#4-teardown)

---

## 1. Prerequisites

### 1.1 System Requirements

- OS: Windows 10/11 64-bit
- Terminal: Git Bash (bundled with Git)

### 1.2 Required Tooling

Install and verify each tool before proceeding.

| Tool | Version | Install |
|---|---|---|
| Git | 2.x+ | https://git-scm.com/download/win |
| AWS CLI | 2.x | https://aws.amazon.com/cli/ |
| kubectl | latest stable | https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/ |
| Terraform | 1.x+ | https://developer.hashicorp.com/terraform/downloads |
| Helm | 3.x+ | https://helm.sh/docs/intro/install/ |
| Docker Desktop | latest | https://www.docker.com/products/docker-desktop/ |
| eksctl | latest | https://eksctl.io/installation/ |

For `kubectl`, `terraform`, `helm`, and `eksctl`: download the binary, place it in a dedicated directory (e.g. `C:\tools\`), and add that directory to your system `PATH`.

Docker Desktop requires WSL 2. Enable it when prompted during installation and restart if required.

**Verify all tools:**
```bash
git --version
aws --version
kubectl version --client
terraform -version
helm version
docker --version
eksctl version
```

### 1.3 AWS Account & CLI Configuration

#### IAM Setup

1. Create an IAM user (`eks-admin`) with programmatic access.
2. Attach `AdministratorAccess` policy.

> **Note:** `AdministratorAccess` is used here for project simplicity. Scope permissions appropriately for any non-isolated environment.

3. Generate and download Access Key credentials.

#### Configure CLI

```bash
aws configure
```

Enter your Access Key ID, Secret Access Key, region (`us-east-1`), and output format (`json`).

**Verify:**
```bash
aws sts get-caller-identity
```

Expected: JSON response with your account ID and user ARN.

### 1.4 Repository Setup

```bash
git clone https://github.com/githubabhay2003/BTech-Major-Project-Cloud-Native-Observability-EKS.git
cd BTech-Major-Project-Cloud-Native-Observability-EKS
```

#### GitHub Actions

- Go to your fork's **Settings → Actions → General** and confirm workflows are enabled.
- No GitHub secrets are required — this project uses AWS OIDC federation for CI/CD authentication.

---

## 2. Provisioning

Follow steps in order. Do not skip ahead.

### Step 1 — Infrastructure Layer

Provisions: VPC, subnets, NAT Gateway, EKS cluster, managed node group, ECR repositories, bastion host, and IAM roles.

```bash
cd terraform/infra

terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

> Takes 10–20 minutes. The EKS control plane provisioning is the longest step.

**Verify cluster exists:**
```bash
aws eks list-clusters --region us-east-1
# Expected: "eks-observability-cluster"
```

---

### Step 2 — Cluster Access

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-observability-cluster
```

**Verify node readiness:**
```bash
kubectl get nodes
# All nodes must show STATUS: Ready before proceeding
```

---

### Step 3 — Platform Layer (Apps)

Provisions: NGINX Ingress Controller, kube-prometheus-stack (Prometheus, Grafana, Alertmanager), Blackbox Exporter, ServiceMonitors, PrometheusRules, Grafana dashboards, and cross-namespace ingress routing.

**Critical:** Install the observability stack and its CRDs before applying the full layer. This avoids `no matches for kind` errors on `ServiceMonitor` and `PrometheusRule` resources.

```bash
cd ../apps

terraform init

# Stage 1 — install monitoring namespace and CRD-producing Helm releases first
terraform apply \
  -target=module.observability.kubernetes_namespace_v1.monitoring \
  -target=module.observability.helm_release.kube_prometheus_stack \
  -target=module.observability.helm_release.prometheus_blackbox_exporter \
  -auto-approve
```

**Verify CRDs are registered before proceeding:**
```bash
kubectl get crd | grep monitoring.coreos.com
# Must include: prometheusrules, servicemonitors, probes, alertmanagers
```

```bash
# Stage 2 — apply remaining resources
terraform apply -auto-approve
```

**Verify pods:**
```bash
kubectl get pods -A
# Expected running pods: ingress-nginx, prometheus, grafana, alertmanager, blackbox-exporter
```

---

### Step 4 — Ingress Controller

```bash
kubectl get svc -n ingress-nginx
```

Wait until `EXTERNAL-IP` shows an `*.amazonaws.com` hostname. This is your ELB URL — note it for use in subsequent steps.

> If `EXTERNAL-IP` shows `<pending>`, wait 2–5 minutes for AWS to provision the ELB.

---

### Step 5 — Application Deployment (CI/CD)

Trigger the GitHub Actions pipeline to build Docker images, push to ECR, and deploy via Helm:

```bash
git commit --allow-empty -m "trigger: deploy applications"
git push
```

Monitor the run under the **Actions** tab in your GitHub repository. All steps must complete with a green status before proceeding.

---

### Step 6 — Confirm Application Deployment

```bash
kubectl get pods -n default
kubectl get deployments -n default
kubectl get ingress -A
```

Expected: `fastapi-app` and `website` pods in `Running` state, ingress resources present.

---

## 3. Verification & Validation

### 3.1 System Health Check

```bash
kubectl get nodes                  # all Ready
kubectl get pods -A                # no CrashLoopBackOff or Pending
kubectl get svc -A                 # LoadBalancer has EXTERNAL-IP
```

### 3.2 Application Endpoints

Replace `<ELB>` with the hostname from `kubectl get svc -n ingress-nginx`.

| URL | Expected Response |
|---|---|
| `http://<ELB>/` | Website homepage |
| `http://<ELB>/api` | `{"message": "FastAPI Observability App"}` |
| `http://<ELB>/grafana` | Grafana login/dashboard |
| `http://<ELB>/prometheus` | Prometheus UI |
| `http://<ELB>/alertmanager` | Alertmanager UI |

**Quick curl validation:**
```bash
ELB=$(kubectl get svc -n ingress-nginx \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

curl -s http://$ELB/api
curl -s -o /dev/null -w "%{http_code}" http://$ELB/
curl -s -o /dev/null -w "%{http_code}" http://$ELB/grafana
```

### 3.3 Prometheus Targets

Open `http://<ELB>/prometheus` → **Status → Targets**

Confirm:
- `fastapi` target: `UP`
- `kubernetes-*` targets: `UP`
- `blackbox` probe for website: `UP`

### 3.4 Grafana Dashboard

Open `http://<ELB>/grafana` → **Dashboards → FastAPI — Golden Signals**

Expected panels: Request Rate (RPS), Error Rate (5xx), P95 Latency, P99 Latency, Container CPU, Container Memory.

### 3.5 Alert Pipeline Validation

**Test 1 — FastAPI failure:**
```bash
kubectl scale deployment fastapi-app --replicas=0 -n default
```

Wait ~60 seconds, then check `http://<ELB>/prometheus` → **Alerts**.

Expected: `FastAPIDown` in `FIRING` state.

```bash
# Restore
kubectl scale deployment fastapi-app --replicas=2 -n default
```

**Test 2 — Website failure:**
```bash
kubectl scale deployment website --replicas=0 -n default
```

Wait ~60 seconds. Expected: `WebsiteDown` in `FIRING` state.

```bash
# Restore
kubectl scale deployment website --replicas=2 -n default
```

If SMTP is configured, email notifications will be sent to the configured address. Email delivery depends on Gmail App Password validity and is independent of the alerting pipeline itself.

### 3.6 Common Issues

| Symptom | Check |
|---|---|
| Pod in `CrashLoopBackOff` | `kubectl logs <pod> -n <namespace>` |
| Pod in `Pending` | `kubectl describe pod <pod> -n <namespace>` (check events for scheduling/image pull errors) |
| `EXTERNAL-IP` pending | Wait 2–5 min; confirm Ingress Controller pods are running |
| `/api` or `/grafana` returning 503 | Check ExternalName proxy services: `kubectl get svc -n default` |
| Prometheus targets down | Verify ServiceMonitor labels match `release: kube-prometheus-stack` |

---

## 4. Teardown

> Run this immediately after testing to avoid ongoing charges.

### Step 1 — Release AWS-Provisioned Resources

Kubernetes LoadBalancer services and Ingress objects cause AWS to provision ELBs and ENIs that Terraform cannot remove while they remain active.

```bash
kubectl delete ingress --all -A
kubectl delete svc -A --field-selector spec.type=LoadBalancer

# Allow AWS time to release ELBs and ENIs
sleep 60
```

**Verify release:**
```bash
kubectl get ingress -A
kubectl get svc -A | grep LoadBalancer
# Both should return: No resources found

aws elb describe-load-balancers --region us-east-1
# Expected: empty LoadBalancerDescriptions
```

If any ELB is still listed, wait 2–3 minutes and re-check before proceeding.

---

### Step 2 — Destroy Apps Layer

```bash
cd terraform/apps
terraform destroy -auto-approve
```

> Takes 5–10 minutes.

---

### Step 3 — Destroy Infrastructure Layer

```bash
cd ../infra
terraform destroy -auto-approve
```

> Takes 10–20 minutes.

---

### Step 4 — Final AWS Verification

Confirm no billable resources remain:

```bash
aws eks list-clusters --region us-east-1
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=instance-state-name,Values=running"
aws elb describe-load-balancers --region us-east-1
aws ec2 describe-nat-gateways --region us-east-1 \
  --filter "Name=state,Values=available"
aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=isDefault,Values=false"
```

All queries should return empty or no project-related resources. If anything persists, check the AWS Console under EC2 → Load Balancers, EC2 → Network Interfaces, and VPC → NAT Gateways.

---

## Reference

| Directory | Purpose |
|---|---|
| `terraform/infra/` | AWS infrastructure (VPC, EKS, ECR, IAM) |
| `terraform/apps/` | Kubernetes platform layer (observability, ingress, RBAC) |
| `helm/fastapi/` | FastAPI application Helm chart |
| `helm/website/` | Static website Helm chart |
| `apps/fastapi/` | FastAPI application source |
| `apps/website/` | Static website source |

Related: `docs/architecture.md` · `docs/challenges-and-learnings.md`
