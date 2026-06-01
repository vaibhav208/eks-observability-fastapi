# Architecture

## Overview

The platform is organized into four distinct layers: external access, CI/CD automation, AWS infrastructure, and observability. Each layer has a defined responsibility with no cross-cutting concerns.

<p align="center">
  <img src="https://raw.githubusercontent.com/githubabhay2003/BTech-Major-Project-Cloud-Native-Observability-EKS/main/docs/images/architecture-image.png" width="100%"><br>
  <b>Figure:</b> <i>End-to-End Architecture of the Cloud-Native Observability Platform on Amazon EKS</i>
</p>


## Layers

### 1. External Layer

Users access the platform via browser through the public internet. Requests enter through an AWS Network Load Balancer provisioned by the NGINX Ingress Controller.

Developers interact via GitHub — a push to `main` triggers the CI/CD pipeline automatically.


### 2. CI/CD Layer

**Pipeline:** GitHub Actions → ECR → EKS (via Helm)

| Component | Role |
|---|---|
| GitHub Actions | Orchestrates the build and deploy workflow |
| OIDC Federation | Authenticates to AWS without static credentials |
| Docker | Builds images for FastAPI and the static website |
| Amazon ECR | Stores container images, tagged by commit SHA |
| Helm | Deploys and upgrades application workloads on EKS |

**Flow:**
1. Developer pushes to `main`
2. GitHub Actions authenticates to AWS via OIDC (no stored secrets)
3. Docker builds both application images; tags with `$GITHUB_SHA`
4. Images pushed to ECR
5. `helm upgrade --install` deploys both services to EKS


### 3. AWS Infrastructure Layer

**Region:** `us-east-1`  
**State backend:** S3 (state file) + DynamoDB (locking)  
**IaC:** Terraform — split into `infra` and `apps` layers

#### Networking (Amazon VPC)

| Subnet | Resources |
|---|---|
| Public | Internet Gateway, NAT Gateway, Bastion Host |
| Private | EKS control plane, managed node group |

Worker nodes run in private subnets with outbound internet access via NAT Gateway. All inbound traffic enters through the public subnet via the NGINX Ingress Controller's LoadBalancer service.

#### EKS Cluster

| Component | Detail |
|---|---|
| NGINX Ingress Controller | Single entry point; path-based routing |
| Static Website | Deployment + Service (port 80); route: `/` |
| FastAPI Backend | Deployment + Service (port 8000); routes: `/api`, `/health`, `/metrics` |

**Path routing:**

```
<ELB>/          →  Website Service
<ELB>/api       →  FastAPI Service
<ELB>/grafana   →  Grafana (monitoring namespace, via ExternalName proxy)
<ELB>/prometheus → Prometheus (monitoring namespace, via ExternalName proxy)
<ELB>/alertmanager → Alertmanager (monitoring namespace, via ExternalName proxy)
```

#### IAM Roles

| Role | Principal | Access |
|---|---|---|
| EKS Cluster Role | EKS control plane | Cluster management |
| EKS Node Role | EC2 node group | ECR read, EKS worker permissions |
| GitHub Actions Role | GitHub OIDC | ECR push, EKS deploy |
| Bastion Role | EC2 bastion host | Cluster admin (kubectl) |


### 4. Observability Layer

**Namespace:** `monitoring`  
**Deployed via:** `kube-prometheus-stack` Helm chart (Prometheus Operator)

#### Components

| Component | Responsibility |
|---|---|
| Prometheus | Scrapes and stores time-series metrics (15s interval, 7-day retention) |
| Grafana | Visualizes metrics; dashboards auto-provisioned via labeled ConfigMaps |
| Alertmanager | Routes alerts from Prometheus to email (Gmail SMTP) |
| Blackbox Exporter | HTTP probes website availability from outside the application |

#### Custom Operator Resources

| Resource | Purpose |
|---|---|
| `ServiceMonitor` (FastAPI) | Instructs Prometheus to scrape FastAPI `/metrics` |
| `PrometheusRule` (FastAPI) | Defines alert thresholds: high error rate, high latency, pod down |
| `Probe` (Website) | Directs Blackbox Exporter to HTTP-check the website service |
| `PrometheusRule` (Website) | Fires `WebsiteDown` alert on probe failure |
| Dashboard ConfigMap | Grafana auto-discovers and loads the FastAPI Golden Signals dashboard |

#### Grafana — FastAPI Golden Signals Dashboard

| Panel | Query |
|---|---|
| Request Rate (RPS) | `rate(http_requests_total[1m])` |
| Error Rate (5xx) | `rate(http_requests_total{status=~"5.."}[1m])` |
| P95 Latency | `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))` |
| P99 Latency | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` |
| Container CPU | `rate(container_cpu_usage_seconds_total[1m])` |
| Container Memory | `container_memory_working_set_bytes` |

#### Alert Rules

| Alert | Condition | Threshold |
|---|---|---|
| `FastAPIHighErrorRate` | 5xx responses per second | > 1 req/s for 1m |
| `FastAPIHighLatency` | P95 response latency | > 1s for 1m |
| `FastAPIDown` | Available replicas | 0 for 30s |
| `WebsiteDown` | Blackbox probe failure | 30s |


## End-to-End Request Flow

```
Browser
  └─▶ AWS NLB
        └─▶ NGINX Ingress Controller
              ├─▶ /          →  Website Service  →  Website Pod
              └─▶ /api       →  FastAPI Service  →  FastAPI Pod
                                                        └─▶ /metrics (scraped by Prometheus)
                                                              └─▶ Grafana (visualized)
                                                              └─▶ Alertmanager (alerts on threshold breach)
                                                                    └─▶ Email notification
```


## Repository Structure

```
.
├── terraform/
│   ├── infra/          # AWS resources: VPC, EKS, ECR, IAM, bastion
│   └── apps/           # Kubernetes platform: ingress, observability, RBAC, routing
├── helm/
│   ├── fastapi/        # FastAPI application Helm chart
│   └── website/        # Static website Helm chart
├── apps/
│   ├── fastapi/        # FastAPI source + Dockerfile
│   └── website/        # Static site source + Dockerfile
└── docs/               # Engineering documentation
```


## Design Decisions

| Decision | Rationale |
|---|---|
| Two-layer Terraform (`infra` / `apps`) | Decouples AWS resource lifecycle from Kubernetes workload lifecycle; allows independent apply/destroy |
| OIDC for GitHub Actions | Eliminates long-lived IAM credentials in CI/CD; tokens are ephemeral per workflow run |
| Helm for application delivery | Enables parameterized, repeatable deployments; CI/CD passes image tag as a Helm value |
| ExternalName services for cross-namespace routing | Ingress is namespace-scoped; ExternalName proxies bridge `default` → `monitoring` without moving Ingress into the monitoring namespace |
| ConfigMap-based dashboard provisioning | Grafana sidecar auto-discovers labeled ConfigMaps; no manual dashboard import required |
| Commit SHA image tagging | Ensures immutable, traceable image versions; eliminates `latest`-tag non-determinism |


