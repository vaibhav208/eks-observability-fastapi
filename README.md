# EKS Observability Platform with Prometheus, Grafana, and FastAPI

A fully automated, rebuild-safe Kubernetes observability platform on AWS EKS using Terraform and Helm, featuring a FastAPI application instrumented with Prometheus metrics, alerting via Alertmanager, and visualization through Grafana.

![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-blue)
![Helm](https://img.shields.io/badge/Helm-Charts-blueviolet)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-red)
![Grafana](https://img.shields.io/badge/Grafana-Visualization-orange)
![Status](https://img.shields.io/badge/Status-Production--Ready-green)


- [Overview](#overview)
- [Skills Demonstrated](#skills-demonstrated)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Setup and Deployment](#setup-and-deployment)
- [CI/CD Pipeline Explanation](#cicd-pipeline-explanation)
- [Verification Steps](#verification-steps)
- [Screenshots](#screenshots)
- [Challenges and Learnings](#challenges-and-learnings)
- [Future Improvements](#future-improvements)
- [Repository Structure](#repository-structure)
- [Contributing Guidelines](#contributing-guidelines)
- [License & Author](#license--author)

## Overview

This project demonstrates a production-style, fully reproducible Kubernetes observability platform on AWS EKS, built using Terraform and Helm as the single sources of truth.

The platform provisions an Amazon EKS cluster inside a custom VPC, deploys a containerized FastAPI application instrumented with Prometheus metrics, and installs a Kubernetes-native monitoring stack using kube-prometheus-stack.

**Key characteristics of the project:**

* **End-to-end automation:** Infrastructure, cluster access, namespaces, applications, monitoring, and alerting are all declaratively managed.
* **Rebuild-safe:** Running `terraform destroy` followed by `terraform apply` restores the entire platform without manual intervention.
* **Real-world observability:** Metrics scraping, dashboards, and alerts are implemented using industry-standard tools and patterns.

This repository is intentionally designed to reflect how observability platforms are built and managed in real production environments.

## Skills Demonstrated

This project demonstrates practical, production-oriented skills across cloud infrastructure, Kubernetes operations, observability, and automation.

### Cloud & Infrastructure
* **Designing and provisioning** a custom AWS VPC with public and private subnets.
* **Deploying and managing** Amazon EKS with managed node groups.
* **Implementing least-privilege IAM roles** and policies for EKS, nodes, and bastion access.
* **Using a bastion host** for secure cluster administration.

### Infrastructure as Code (IaC)
* **End-to-end infrastructure provisioning** using Terraform.
* **Managing Kubernetes resources declaratively** via:
  * `helm_release`
  * `kubernetes_manifest`
  * `kubernetes_namespace_v1`
* **Handling real-world Terraform issues:**
  * Namespace lifecycle and termination.
  * Resource ordering and dependencies.
  * Safe rebuilds using `terraform destroy` and `terraform apply`.

### Kubernetes
* **Namespace isolation** (observability, monitoring).
* **Deploying and managing applications** via Helm.
* **Service discovery** using Kubernetes labels and selectors.
* **Using Kubernetes-native CRDs:**
  * `ServiceMonitor`
  * `PrometheusRule`

### Observability & Monitoring
* **Deploying kube-prometheus-stack** (Prometheus, Grafana, Alertmanager).
* **Automatic metrics discovery** using `ServiceMonitor`.
* **Designing Golden Signals monitoring:**
  * Latency
  * Traffic
  * Errors
  * Saturation
* **Writing PromQL-based alert rules.**
* **Validating alerts** through controlled failure scenarios.
* **Grafana dashboard provisioning** using JSON files (no manual UI creation).

### Operations & Debugging
* **Diagnosing Helm and Kubernetes failures:**
  * Admission webhook issues.
  * Namespace termination conflicts.
  * CRD readiness timing.
* **Reading and interpreting logs** from:
  * Prometheus
  * Grafana
  * Alertmanager
* **Understanding automation boundaries** (what to automate vs. what to keep manual for security/access).

### Professional Engineering Practices
* **Clean separation of concerns** between infrastructure, platform, and application layers.
* **Rebuild-safe, version-controlled** observability setup.
* **Clear operational documentation** and verification steps.
* **Production-aligned design decisions** suitable for technical interviews and real-world teams.

## Architecture

### Visual Overview
<img width="2816" height="1536" alt="Gemini_Generated_Image_yth7y0yth7y0yth7" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/13#issue-4065483458" />


### High-Level Architecture Overview
This project implements a Kubernetes-native observability platform on AWS using Amazon EKS. The architecture is designed to be secure, modular, and rebuild-safe using Infrastructure as Code (Terraform).

### Architecture Components

#### 1. AWS Infrastructure
* **VPC (Custom):** * **Public subnets:** Hosts the **Bastion host** and **NAT Gateway**.
    * **Private subnets:** Hosts **EKS worker nodes**, application pods, and the monitoring stack.
* **Bastion Host (EC2):** Secure administrative access point used to run `kubectl`, `helm`, and operational commands. No direct public access is allowed to EKS nodes.
* **Amazon EKS:** Managed Kubernetes control plane with an Ubuntu-based **Managed Node Group** (`m7i-flex.large`).

#### 2. Kubernetes Namespaces
* **`observability`**: Contains the **FastAPI application**, its Service, and metrics endpoints.
* **`monitoring`**: Contains the **kube-prometheus-stack** (Prometheus, Grafana, Alertmanager) and CRDs like `ServiceMonitor`.

#### 3. Observability Stack
* **Prometheus:** Scrapes cluster and application metrics; automatically discovers targets via `ServiceMonitor`.
* **Grafana:** Visualizes metrics using **version-controlled JSON dashboards** (no manual UI setup required).
* **Alertmanager:** Evaluates `PrometheusRule` conditions and manages alert states.

### Traffic & Data Flow
1. **FastAPI** exposes a `/metrics` endpoint.
2. **ServiceMonitor** (in the `monitoring` namespace) discovers the FastAPI service.
3. **Prometheus** scrapes metrics at defined intervals.
4. **Grafana** queries Prometheus to populate real-time dashboards.
5. **PrometheusRule** evaluates alert conditions; if triggered, **Alertmanager** handles the notification state.

### Design Principles
* **Kubernetes-native:** No external agents; everything runs within the cluster.
* **Declarative:** Entire stack is defined in code.
* **Separation of Concerns:** Clear boundaries between application and platform layers.
* **Rebuild-safe:** Guaranteed consistency across repeated `terraform destroy` and `terraform apply` cycles.

## Tech Stack

The project uses a modern, production-grade cloud-native stack focused on automation, observability, and reliability.

| Category | Tool / Service |
| :--- | :--- |
| **Cloud Provider** | AWS (Amazon Web Services) |
| **Container Orchestration** | Amazon EKS (Elastic Kubernetes Service) |
| **Infrastructure as Code** | Terraform |
| **Package Management** | Helm |
| **Kubernetes Management** | `kubectl` |
| **Application Framework** | FastAPI (Python) |
| **Monitoring** | Prometheus |
| **Visualization** | Grafana |
| **Alerting** | Alertmanager |
| **Metrics Discovery** | ServiceMonitor (Prometheus Operator) |
| **Alert Rules** | PrometheusRule |
| **Container Registry** | Amazon ECR |
| **Compute** | EC2 (Bastion Host, EKS Nodes) |
| **Networking** | VPC, Subnets, NAT Gateway |
| **Authentication** | AWS IAM, `aws-auth` ConfigMap |
| **Operating System** | Amazon Linux (Bastion), Ubuntu (EKS Nodes) |

## Prerequisites

Before deploying this project, ensure the following prerequisites are met. All tools listed below were explicitly used during the implementation.

### 1. AWS Account
An active AWS account with sufficient permissions to create EKS, EC2, IAM, VPC, and ECR resources.
* **AWS Console:** [https://aws.amazon.com/console/](https://aws.amazon.com/console/)

### 2. AWS CLI
Used for authentication, EKS kubeconfig generation, and general AWS interaction.
* **Install guide:** [AWS CLI Installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* **Verify:**
```bash
aws --version
```
### 3. Terraform
Used as the single source of truth for infrastructure and Kubernetes resources.

- **Install guide:** [Official Installation Instructions](https://developer.hashicorp.com/terraform/install)
- **Required version:** `>= 1.5.0`

**Verify installation:**
```bash
terraform version
```
### 4. kubectl
Used to interact with the EKS cluster from the bastion host and locally.

- **Install guide:** [Official Installation Instructions](https://kubernetes.io/docs/tasks/tools/)
- **Verify installation:**
```bash
kubectl version --client
```
### 5. Helm
Used to deploy Kubernetes packages such as FastAPI and kube-prometheus-stack.

- **Install guide:** [Official Installation Instructions](https://helm.sh/docs/intro/install/)
- **Verify installation:**
```bash
helm version
```
### 6. Docker
Used to build the FastAPI container image locally before pushing to Amazon ECR.

- **Install guide:** [Official Installation Instructions](https://docs.docker.com/get-docker/)
- **Verify installation:**
```bash
docker version
```
### 7. Git
Used for version control and repository management.

- **Install guide:** [Official Installation Instructions](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- **Verify installation:**
```bash
git --version
```

## Setup and Deployment
This section describes the exact steps to provision infrastructure and deploy applications using Terraform and Helm. All steps reflect what was implemented in this project.

### 1. Clone the Repository
```bash
git clone https://github.com/vaibhav208/eks-observability-fastapi.git
cd eks-observability/terraform
```
### 2. Initialize Terraform
Initialize Terraform and download required providers.

```bash
terraform init
```
### 3. Validate Terraform Configuration
Check the syntax and internal consistency of the configuration files.

```bash
terraform validate
```
### 4. Review the Execution Plan
Generate and review an execution plan to see what resources Terraform will create, modify, or destroy.

```bash
terraform plan
```
### 5. Apply Infrastructure and Kubernetes Resources
This command provisions:

* **VPC, subnets, routing, NAT**
* **EKS cluster and managed node group**
* **Bastion EC2 instance**
* **aws-auth ConfigMap**
* **Kubernetes namespaces**
* **FastAPI deployment via Helm**
* **kube-prometheus-stack via Helm**
* **ServiceMonitor and PrometheusRule objects**

```bash
terraform apply
```
Note: Confirm with yes when prompted.

### 6. Configure kubectl Access (Bastion or Local)
If running locally or after a rebuild, update your `kubeconfig` to point to the new cluster:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-observability-cluster
```
**Verify cluster access:**
```bash
kubectl get nodes
```
### 7. Accessing Cluster Services (Manual, Expected)
For security and simplicity, no ingress is exposed. Local access is performed via port-forwarding.

#### Grafana
Run the following command to access the Grafana dashboard:

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```
**Credentials:**

* **Username:** `admin`
* **Password:** Retrieved from the Kubernetes secret by running:

```bash
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```
**Access URL: http://localhost:3000**
#### Prometheus
Run the following command to access the Prometheus expression browser:

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```
**Access URL: http://localhost:9090**

#### Alertmanager
Run the following command to access the Alertmanager UI:

```bash
kubectl port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 -n monitoring
```
**Access URL: http://localhost:9093**

### 8. Validate Application Metrics
Ensure that the Prometheus Operator has discovered the FastAPI `ServiceMonitor` and is successfully scraping metrics.

**Check ServiceMonitor status:**
```bash
kubectl get servicemonitor -n monitoring
```
**Confirm FastAPI targets in Prometheus:**

1.  **Navigate:** In the Prometheus UI ([http://localhost:9090](http://localhost:9090)), go to **Status** → **Targets**.
2.  **Verify:** Locate the `fastapi` job entry.
3.  **Check Status:** Ensure the endpoint state is **UP** (indicated by a green background/label).

### 9. Destroy and Rebuild (Reproducibility Test)
To validate full automation and ensure there are no manual dependencies, you can perform a reproducibility test.

**To validate full automation:**
```bash
terraform destroy
terraform apply
```
**After re-apply, only port-forward commands are required again. No manual cluster setup is needed.**

## CI/CD Pipeline Explanation

**Status:** Partially implemented by design  
**Reason:** This project intentionally focuses on infrastructure and observability first. CI/CD is scoped as a follow-up enhancement.

---

### 1. Current Delivery Model (What Exists Now)

At the current stage, the project uses a GitOps-ready but manually triggered workflow:

* **Source of truth:** GitHub repository
* **Infrastructure provisioning:** Terraform (manual execution)
* **Application deployment:** Helm (invoked via Terraform)
* **Observability stack:** Helm (kube-prometheus-stack via Terraform)

**This ensures:**

* Fully reproducible environments
* Deterministic infrastructure state
* Clean separation between infra, app, and observability

---

### 2. Intended CI/CD Flow (Design-Level)

The repository is structured so that adding CI/CD requires no refactor, only automation.

**Planned pipeline stages:**

1.  **Code Commit (GitHub)**
    * FastAPI code changes
    * Terraform / Helm changes
2.  **CI Stage**
    * Lint FastAPI code
    * Run unit tests
    * Build Docker image
    * Push image to Amazon ECR
3.  **CD Stage**
    * Terraform plan (dry-run)
    * Terraform apply (approved environments)
    * Helm upgrade triggered automatically

---

### 3. Example CI/CD Tools (Not Implemented Yet)

| Stage | Tool |
| :--- | :--- |
| **CI** | GitHub Actions |
| **Image Build** | Docker |
| **Registry** | Amazon ECR |
| **CD** | Terraform + Helm |
| **Secrets** | GitHub Secrets / AWS Secrets Manager |

---

### 4. Why CI/CD Is Deferred in This Phase

This project intentionally separates concerns:

* **Phase 1:** Infrastructure foundation
* **Phase 2:** Kubernetes-native observability
* **Phase 3 (future):** CI/CD + GitOps + tracing

This mirrors real-world production rollouts, where observability is validated before automating deployments.

## Verification Steps

This section outlines exact, repeatable steps to verify that the infrastructure, application, and observability stack are working correctly after a fresh terraform apply.

These steps are intentionally manual where appropriate and mirror real-world validation workflows.

### 1. Infrastructure Verification (Terraform)

After terraform apply completes successfully:

```bash
terraform output
```
Verify that the following outputs exist:

- eks_cluster_name
- bastion_public_ip
- vpc_id
- public_subnet_ids
- private_subnet_ids
- ecr_repository_url

This confirms that:

- Networking is provisioned
- EKS cluster is created
- Bastion host is reachable
- ECR repository exists

### 2. Kubernetes Access Verification

SSH into the bastion host:

```bash
ssh -i <key>.pem ec2-user@<bastion_public_ip>
```
Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-observability-cluster
```
Verify cluster access:
```bash
kubectl get nodes
```
Expected:
Worker nodes in Ready state

### 3. Application Verification (FastAPI)

Check FastAPI deployment:

```bash
kubectl get pods -n observability
kubectl get svc -n observability
```
Verify metrics endpoint is exposed:
```bash
kubectl exec -n observability deploy/fastapi -- curl localhost:8000/metrics
```
Expected:
- Prometheus-format metrics output
- HTTP 200 response
- 
### 4. Monitoring Stack Verification

Check kube-prometheus-stack components:

```bash
kubectl get pods -n monitoring
```
Expected running components:
- Prometheus
- Alertmanager
- Grafana
- kube-state-metrics
- node-exporter
- Prometheus Operator

### 5. Prometheus Target Verification

Port-forward Prometheus:

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```
In browser:
```text
http://localhost:9090/targets
```
Verify:
- fastapi target is UP
- Kubernetes system targets are healthy

### 6. ServiceMonitor Verification

Confirm ServiceMonitor exists:

```bash
kubectl get servicemonitor -n monitoring
```
Describe FastAPI ServiceMonitor:
```bash
kubectl describe servicemonitor fastapi -n monitoring
```
Expected:
- Correct namespace selector (observability)
- Endpoint /metrics
- Scrape interval configured

### 7. Grafana Verification

Port-forward Grafana:

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```
**Access: http://localhost:3000**

Login:

Username: admin

Password: retrieved from Kubernetes secret

```bash
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```
Verify:
- Kubernetes dashboards are present
- Prometheus datasource is configured
- FastAPI metrics are queryable

### 8. Alert Rules Verification

Verify PrometheusRules:

```bash
kubectl get prometheusrule -n monitoring
```
Expected:
- fastapi-alerts present
- Default kube-prometheus rules present

Trigger a test alert:
```bash
kubectl scale deployment fastapi -n observability --replicas=0
```
Then check in Prometheus UI:
- Alert transitions to Firing

Restore service:
```bash
kubectl scale deployment fastapi -n observability --replicas=2
```
### 9. Rebuild-Safety Verification (Critical)

Run full teardown:

```bash
terraform destroy -auto-approve
```
Recreate:
```bash
terraform apply -auto-approve
```
**Re-run all checks above**

Expected:
- No manual fixes
- No orphaned resources
- Monitoring stack fully functional again

## Screenshots

This section highlights the end-to-end observability setup, infrastructure provisioning, and alerting verification implemented in this project.

### 1️⃣ Terraform Infrastructure Provisioning (Apply Successful)
<img width="1919" height="1021" alt="Screenshot 2026-01-28 140849" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/12#issue-4065472368" />

**Description:**  
Terraform successfully provisions the complete AWS and Kubernetes infrastructure, including:

- VPC and subnets
- EKS cluster and node groups
- Bastion host
- Amazon ECR repository
- kube-prometheus-stack via Helm
- FastAPI ServiceMonitor

The output confirms that all resources were created without errors and displays key outputs such as:

- Bastion public IP
- EKS cluster name
- ECR repository URL
- VPC and subnet IDs

### 2️⃣ Amazon ECR – FastAPI Container Registry
<img width="1919" height="963" alt="Screenshot 2026-01-28 140834" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/11#issue-4065466611" />

**Description:**  
This screenshot shows the private Amazon ECR repository created for the FastAPI application.  
The repository is used to store container images that are deployed to the EKS cluster.

**Key points:**

- Private ECR repository
- Encrypted using AES-256
- Integrated with Terraform
- Used by Kubernetes deployments

### 3️⃣ Amazon EKS Cluster – Active and Healthy
<img width="1919" height="969" alt="Screenshot 2026-01-28 140745" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/10#issue-4065460961" />

**Description:**  
The Amazon EKS cluster is in an Active state and running a supported Kubernetes version.  
This cluster serves as the core platform for deploying FastAPI and the observability stack.

### 4️⃣ Amazon EC2 – Worker Nodes and Bastion Host
<img width="1919" height="965" alt="Screenshot 2026-01-28 140722" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/9#issue-4065456972" />

**Description:**  
This view shows all EC2 instances associated with the project:

- Managed EKS worker nodes
- Bastion host for secure cluster access

All instances pass health checks, confirming a stable infrastructure layer.

### 5️⃣ Prometheus Targets – Service Discovery Verified
<img width="1919" height="953" alt="Screenshot 2026-01-28 140303" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/8#issue-4065449298" />

**Description:**  
Prometheus successfully discovers and scrapes metrics from:

- FastAPI ServiceMonitor
- Kubernetes components
- Node exporters
- kube-state-metrics
- Alertmanager
- Grafana

All targets are UP, confirming correct ServiceMonitor and label configuration.

### 6️⃣ Prometheus Alerts – FastAPI Rules Loaded
<img width="1919" height="974" alt="Screenshot 2026-01-28 140319" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/7#issue-4065442946" />

**Description:**  
Custom Prometheus alert rules for FastAPI are successfully loaded, including:

- High 5xx error rate
- High latency (P95)
- FastAPI pod down detection

The rules appear under the `fastapi.rules` group and are actively evaluated by Prometheus.

### 7️⃣ Alertmanager – Alert Routing and Status
<img width="1107" height="896" alt="Screenshot 2026-01-27 174432" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/6#issue-4065435833" />

**Description:**  
Alertmanager is operational and receiving alerts from Prometheus.  
The UI shows grouped alerts, routing behavior, and alert states (active/inactive), validating the alert pipeline.

### 8️⃣ Grafana – FastAPI Golden Signals Dashboard
<img width="1919" height="913" alt="Screenshot 2026-01-28 135910" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/5#issue-4065430208" />

**Description:**  
This dashboard visualizes FastAPI Golden Signals:

- Request rate (RPS)
- Error rate (5xx)
- Latency (P95 / P99)
- CPU usage
- Memory usage

Metrics are sourced directly from Prometheus and updated in near real time.

### 9️⃣ Grafana – Prometheus Overview Dashboard
<img width="1919" height="960" alt="Screenshot 2026-01-28 140111" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/4#issue-4065422963" />

**Description:**  
Provides a high-level view of Prometheus health and performance, including:

- Target discovery
- Scrape duration
- Sample ingestion rate
- Storage metrics

Useful for monitoring the observability platform itself.

### 🔟 Grafana – Kubernetes API Server Dashboard
<img width="1919" height="959" alt="Screenshot 2026-01-28 140152" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/3#issue-4065415747" />

**Description:**  
This dashboard tracks Kubernetes control-plane health, showing:

- API availability
- Request latency
- Error rates
- SLI/SLO metrics

Confirms cluster stability and API server reliability.

### 1️⃣1️⃣ Prometheus Alert Rules – FastAPI Application
<img width="1886" height="913" alt="Screenshot 2026-01-27 170504" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/2#issue-4065405014" />


This screenshot shows custom PrometheusRule objects for the FastAPI application:
- FastAPIHighErrorRate
- FastAPIHighLatency
- FastAPIPodDown

## Challenges and Learnings

|  | Challenge | Root Cause | Approach Taken | Key Learning |
|---|---------|-----------|----------------|--------------|
| 1 | Terraform failed to create `ServiceMonitor` and `PrometheusRule` resources | Prometheus Operator CRDs were not yet available when Terraform applied Kubernetes manifests | Enforced strict resource ordering by deploying `kube-prometheus-stack` via Helm first and applying CRD-dependent resources only after Helm completion | CRDs must exist before creating custom Kubernetes resources; Helm releases installing CRDs should be treated as hard dependencies |
| 2 | `namespace monitoring is being terminated` error during re-apply | Terraform attempted to recreate resources while the namespace was still in `Terminating` state after destroy | Verified namespace status and waited for full deletion before reapplying infrastructure | Kubernetes namespaces may take time to terminate; never reapply resources into terminating namespaces |
| 3 | `kubernetes_manifest` schema validation errors | Non-Kubernetes fields like `depends_on` were incorrectly placed inside Kubernetes manifests | Moved Terraform meta-arguments (`depends_on`) to the resource level instead of inside the manifest block | `kubernetes_manifest` strictly validates against Kubernetes OpenAPI schema; Terraform logic must remain outside Kubernetes YAML |
| 4 | Alertmanager port-forward timeout | Incorrect assumption about service ports and missing Alertmanager pods | Verified service configuration and pod availability before port-forwarding | Always inspect Kubernetes services and pods before attempting access; service ports must match target ports |
| 5 | Alertmanager pods not found during restart attempts | Incorrect StatefulSet and pod naming assumptions | Used `kubectl get statefulsets` and `kubectl get pods` to identify correct resource names | Resource names created by Helm charts often differ from expected defaults; always query live cluster state |
| 6 | Multiple system alerts firing unexpectedly | Control-plane components in managed EKS environments behave differently from self-managed clusters | Verified alert behavior in Prometheus UI and acknowledged expected behavior during bootstrap | Not all default alerts indicate real failures; alert tuning is required for managed Kubernetes services |
| 7 | Email alert delivery failures in Alertmanager | SMTP configuration and secret handling required additional setup and validation | Temporarily disabled email notifications and focused on validating alerts in Alertmanager UI | Incremental observability implementation is critical; verify alert generation before configuring notification channels |
| 8 | Helm release taking several minutes to complete | `kube-prometheus-stack` deploys multiple components and CRDs | Allowed sufficient timeout and monitored Helm release progress | Large Helm charts require patience and proper timeout handling |
| 9 | Prometheus targets not appearing initially | ServiceMonitor label selector mismatch | Corrected labels to match `kube-prometheus-stack` release selector | Label consistency is critical for Prometheus target discovery |
| 10 | End-to-end observability verification complexity | Multiple tools involved (EKS, Prometheus, Grafana, Alertmanager) | Verified each layer independently: targets, metrics, alerts, dashboards | Observability should be validated layer-by-layer, not assumed from successful deployment |

##  Future Improvements

The current implementation establishes a strong observability foundation. The following enhancements can further improve scalability, security, and production readiness:

- **Alert Notification Integrations**
  - Enable and validate Alertmanager integrations such as Slack, PagerDuty, or Opsgenie
  - Implement alert grouping and routing strategies based on severity and service

- **SLOs and Error Budgets**
  - Define Service Level Objectives (SLOs) for FastAPI using Prometheus recording rules
  - Track error budgets and integrate them into alerting decisions

- **Autoscaling Enhancements**
  - Introduce Horizontal Pod Autoscaler (HPA) based on custom Prometheus metrics
  - Implement Cluster Autoscaler for dynamic node scaling

- **Security Hardening**
  - Enable IAM Roles for Service Accounts (IRSA)
  - Enforce network policies for observability components
  - Add secrets management using AWS Secrets Manager or External Secrets Operator

- **CI/CD Automation**
  - Add GitHub Actions pipeline for Terraform validation and deployment
  - Implement automated image build and push to Amazon ECR

- **Multi-Environment Support**
  - Extend Terraform modules to support `dev`, `staging`, and `prod` environments
  - Introduce environment-specific alert thresholds and dashboards

---

##  Repository Structure
<img width="534" height="983" alt="Screenshot 2026-01-28 154954" src="https://github.com/vaibhav208/eks-observability-fastapi/issues/1#issue-4065385729" />

## Contributing

Contributions are welcome and encouraged.

### Guidelines

- Fork the repository
- Create a feature branch

```bash
git checkout -b feature/your-feature-name
```
- Commit your changes with clear messages
- Push to your fork and open a Pull Request
- Ensure Terraform formatting and validation:
```bash
terraform fmt -recursive
terraform validate
```
Please ensure changes are well-documented and aligned with existing project structure.

## License

This project is licensed under the MIT License.

You are free to use, modify, and distribute this project with proper attribution.

See the LICENSE file for full license text.

## 👤 Author

**Vaibhav Sarkar**

**Role:** DevOps / Cloud Engineer  

**Focus Areas:** AWS, Kubernetes, Terraform, Observability, SRE Practices  

**GitHub:** https://github.com/vaibhav208  

**LinkedIn:** https://www.linkedin.com/in/vaibhav-sarkar/








