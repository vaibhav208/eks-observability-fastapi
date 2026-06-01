# Infrastructure

Terraform manages all AWS infrastructure across two independent root modules. The split enforces a clean lifecycle boundary — AWS resources and Kubernetes platform resources can be provisioned, updated, and destroyed independently.

| Layer | Path | Manages |
|---|---|---|
| Infra | `terraform/infra/` | VPC, EKS, ECR, IAM, bastion host |
| Apps | `terraform/apps/` | Ingress controller, observability stack, RBAC, ingress routing |

**State backend:** S3 (`eks-observability-tf-state-<account-id>`) with DynamoDB locking (`eks-observability-tf-lock`). The `apps` layer reads infra outputs via `terraform_remote_state`.


## Infra Layer (`terraform/infra`)

### Networking

Single VPC across two availability zones (`us-east-1a`, `us-east-1b`).

| Subnet | Resources |
|---|---|
| Public (x2) | Internet Gateway, NAT Gateway, Bastion Host |
| Private (x2) | EKS control plane endpoint, managed node group |

One NAT Gateway serves both private subnets (single-AZ). Worker nodes in private subnets reach the internet via NAT; all inbound traffic enters through the public subnet via the NGINX Ingress Controller's LoadBalancer.

### EKS Cluster

- Managed control plane (AWS-managed)
- Managed node group in private subnets
- Node group configured with min/max/desired capacity for autoscaling

### IAM Roles

| Role | Principal | Purpose |
|---|---|---|
| `eks-cluster-role` | EKS service | Control plane management |
| `eks-node-role` | EC2 (node group) | ECR image pull, EKS worker bootstrap |
| `github-actions-role` | GitHub OIDC | ECR push, `eks:DescribeCluster`, Helm deploy |
| `bastion-role` | EC2 (bastion) | `kubectl` / `helm` cluster admin access |

The GitHub Actions role uses OIDC federation — no static IAM credentials are stored anywhere. The trust policy is scoped to the specific repository and branch pattern.

### Bastion Host

EC2 instance (`t3.micro`, Amazon Linux 2023) in a public subnet. `kubectl` and `helm` are pre-installed via user data. Used for out-of-band cluster access and administrative operations. Mapped to `system:masters` in `aws-auth`.

> See [Security Known Issues](challenges-and-learnings.md#21-security-hardcoded-credentials--excessive-permissions) — SSH access is currently open to `0.0.0.0/0` and is flagged for restriction.

### Amazon ECR

Two repositories:
- `eks-observability-fastapi`
- `eks-observability-website`

Both have `force_delete = true` to allow clean Terraform teardown.

### Remote State

```hcl
# terraform/infra/backend.tf
backend "s3" {
  bucket         = "eks-observability-tf-state-<account-id>"
  key            = "infra/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "eks-observability-tf-lock"
}
```

```hcl
# terraform/apps — consuming infra outputs
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "eks-observability-tf-state-<account-id>"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
```


## Apps Layer (`terraform/apps`)

### Kubernetes RBAC (`aws-auth`)

Managed as a `kubernetes_config_map_v1_data` resource. Maps three IAM roles to Kubernetes groups:

| IAM Role | Kubernetes Group |
|---|---|
| EKS node role | `system:bootstrappers`, `system:nodes` |
| Bastion role | `system:masters` |
| GitHub Actions role | `system:masters` |

Managing `aws-auth` in Terraform prevents configuration loss on infrastructure recreation — a known failure mode when ConfigMaps are edited manually.

### NGINX Ingress Controller

Installed via `helm_release` into the `ingress-nginx` namespace. Provisioned as a `LoadBalancer` service — AWS creates an NLB/ELB automatically. This is the single external entry point for all traffic.

### Observability Module (`module.observability`)

Deploys the full monitoring stack into the `monitoring` namespace via `kube-prometheus-stack`:

| Resource | Type | Detail |
|---|---|---|
| `kube-prometheus-stack` | `helm_release` | Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics |
| `prometheus-blackbox-exporter` | `helm_release` | HTTP uptime probing for the website |
| `ServiceMonitor` (FastAPI) | `kubernetes_manifest` | Scrapes FastAPI `/metrics` every 15s |
| `PrometheusRule` (FastAPI) | `kubernetes_manifest` | Alert rules: high error rate, high latency, pod down |
| `Probe` (Website) | `kubernetes_manifest` | Blackbox HTTP probe every 30s |
| `PrometheusRule` (Website) | `kubernetes_manifest` | `WebsiteDown` alert on probe failure |
| Dashboard ConfigMap | `kubernetes_config_map_v1` | Grafana auto-discovers via `grafana_dashboard: "1"` label |

All `kubernetes_manifest` resources depend on `helm_release.kube_prometheus_stack` via `depends_on` to ensure CRDs are registered before use.

### Observability Ingress Routing

The `Ingress` resource lives in the `default` namespace but backing services are in `monitoring`. Kubernetes Ingress cannot route directly across namespaces, so `ExternalName` services in `default` act as DNS proxies:

```
default/grafana-proxy     →  kube-prometheus-stack-grafana.monitoring.svc.cluster.local
default/prometheus-proxy  →  kube-prometheus-stack-prometheus.monitoring.svc.cluster.local
default/alertmanager-proxy →  kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local
```

Ingress path mapping:

| Path | Backend Service |
|---|---|
| `/` | Website (`default` namespace) |
| `/api` | FastAPI (`default` namespace) |
| `/grafana` | `grafana-proxy` ExternalName service |
| `/prometheus` | `prometheus-proxy` ExternalName service |
| `/alertmanager` | `alertmanager-proxy` ExternalName service |


## Module Structure

```
terraform/
├── infra/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   ├── backend.tf
│   └── modules/
│       ├── network/       # VPC, subnets, IGW, NAT Gateway
│       ├── eks/           # EKS cluster and managed node group
│       ├── iam/           # All IAM roles (cluster, node, bastion, GitHub Actions)
│       ├── ecr/           # ECR repositories
│       └── bastion/       # Bastion host EC2 instance
└── apps/
    ├── main.tf
    ├── remote-state.tf
    ├── helm-nginx-ingress.tf
    ├── helm-kube-prometheus.tf
    ├── aws-auth.tf
    └── modules/
        └── observability/ # ServiceMonitors, PrometheusRules, Probes, dashboards, routing
```


## Deployment Order

The dependency chain between layers requires staged execution:

```
terraform/infra apply
  └─▶ aws eks wait cluster-active
      └─▶ aws eks update-kubeconfig
          └─▶ terraform/apps apply (stage 1: monitoring namespace + CRD-producing Helm releases)
              └─▶ kubectl get crd | grep monitoring.coreos.com  ← gate
                  └─▶ terraform/apps apply (stage 2: full apply)
```



