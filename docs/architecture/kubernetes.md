# Kubernetes & Helm

Application workloads are packaged as Helm charts and deployed to EKS via the CI/CD pipeline. The observability stack is deployed separately through Terraform's `helm_release` resource.


## Charts

| Chart | Path | Namespace | Purpose |
|---|---|---|---|
| `fastapi` | `helm/fastapi/` | `default` | FastAPI backend service |
| `website` | `helm/website/` | `default` | Static website (NGINX) |

The observability stack (`kube-prometheus-stack`, Blackbox Exporter) is managed by Terraform — see [`docs/infrastructure.md`](infrastructure.md#observability-module-moduleobservability).



## Resource Definitions

Each chart defines the following Kubernetes resources:

### Deployment

Both workloads run with 2 replicas. FastAPI includes liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 15

readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 10
```

> Resource requests and limits are not currently defined (`resources: {}`). This is a known gap — see [challenges-and-learnings.md §31](challenges-and-learnings.md#31-fastapi-deployment-not-production-ready).

### Service

Both workloads use `ClusterIP` services — external access is handled exclusively through the Ingress layer, not via `LoadBalancer`-type services.

| Service | Port | Target Port |
|---|---|---|
| `fastapi-app` | 8000 | 8000 |
| `website` | 80 | 80 |

### Ingress

Managed by the NGINX Ingress Controller. Path routing:

| Path | Service | PathType |
|---|---|---|
| `/` | `website` | `Prefix` |
| `/api(/\|$)(.*)` | `fastapi-app` | `ImplementationSpecific` |

The FastAPI route uses a regex with `rewrite-target: /$2` to strip the `/api` prefix before forwarding to the application. The website route uses a plain `Prefix` match with no rewrite.

Ingress resource names are templated using `{{ .Release.Name }}` to prevent naming conflicts across deployments:

```yaml
metadata:
  name: {{ .Release.Name }}-ingress
```


## values.yaml

Key configurable values per chart:

```yaml
# helm/fastapi/values.yaml
replicaCount: 2

image:
  repository: ""     # injected by CI/CD: <account>.dkr.ecr.<region>.amazonaws.com/eks-observability-fastapi
  tag: ""            # injected by CI/CD: $GITHUB_SHA
  pullPolicy: Always

service:
  type: ClusterIP
  port: 8000

ingress:
  enabled: true
  className: nginx
```

```yaml
# helm/website/values.yaml
replicaCount: 2

image:
  repository: ""     # injected by CI/CD
  tag: ""
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80
```


## Deployment

### CI/CD (standard path)

The GitHub Actions pipeline builds, tags, and deploys on every push to `main`:

```bash
helm upgrade --install fastapi-app ./helm/fastapi \
  --namespace default \
  --set image.repository=$ECR_REGISTRY/eks-observability-fastapi \
  --set image.tag=$GITHUB_SHA

helm upgrade --install website ./helm/website \
  --namespace default \
  --set image.repository=$ECR_REGISTRY/eks-observability-website \
  --set image.tag=$GITHUB_SHA
```

`--install` makes the command idempotent — it installs on first run and upgrades on subsequent runs.

### Manual deployment

```bash
# Set environment
export AWS_REGION=us-east-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export IMAGE_TAG=<commit-sha>

# Deploy FastAPI
helm upgrade --install fastapi-app ./helm/fastapi \
  --namespace default \
  --set image.repository=$ECR_REGISTRY/eks-observability-fastapi \
  --set image.tag=$IMAGE_TAG

# Deploy Website
helm upgrade --install website ./helm/website \
  --namespace default \
  --set image.repository=$ECR_REGISTRY/eks-observability-website \
  --set image.tag=$IMAGE_TAG
```


## Validation

```bash
# Release status
helm list -n default
helm status fastapi-app -n default

# Pod health
kubectl get pods -n default
kubectl rollout status deployment/fastapi-app -n default
kubectl rollout status deployment/website -n default

# Application endpoints
kubectl get ingress -n default

# FastAPI health and metrics
kubectl port-forward deployment/fastapi-app 8000:8000 -n default
curl http://localhost:8000/health
curl http://localhost:8000/metrics
```


## Rollback

```bash
# View release history
helm history fastapi-app -n default

# Roll back to previous revision
helm rollback fastapi-app -n default

# Roll back to a specific revision
helm rollback fastapi-app 2 -n default
```


## Troubleshooting

| Symptom | Command |
|---|---|
| Pod not starting | `kubectl describe pod <pod> -n default` |
| Image pull failure | `kubectl get events -n default --sort-by='.lastTimestamp'` |
| Helm release stuck in failed state | `helm uninstall <release> -n default && helm upgrade --install ...` |
| Ingress not routing correctly | `kubectl describe ingress -n default` |
| Application logs | `kubectl logs -l app=fastapi -n default --tail=100` |

