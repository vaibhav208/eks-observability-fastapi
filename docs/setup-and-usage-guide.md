# A Comprehensive Execution and Observability Guide for a Cloud-Native Application on AWS EKS Using Terraform, Kubernetes, and CI/CD Pipelines

## Abstract

This document presents a complete, reproducible guide for deploying, validating, and decommissioning a cloud-native application on Amazon Elastic Kubernetes Service (EKS). It integrates modern DevOps and cloud engineering practices, including Infrastructure as Code (Terraform), containerization (Docker), Kubernetes orchestration, and continuous integration/continuous deployment (CI/CD) via GitHub Actions.

The guide systematically walks users through environment setup on a Windows system, AWS account configuration, and the provisioning of core cloud infrastructure such as virtual networks, IAM roles, EKS clusters, and container registries. It further details the deployment of application workloads using Helm, alongside a comprehensive observability stack consisting of Prometheus, Grafana, Alertmanager, and Blackbox Exporter for monitoring, visualization, and alerting.

A key contribution of this document is its emphasis on operational validation, including metrics verification, dashboard analysis, and failure simulation to demonstrate alerting mechanisms. Additionally, it provides a structured teardown process to safely remove all resources, minimizing unnecessary cloud costs.

Designed for both academic and practical use, this guide enables users to understand and implement a full lifecycle cloud-native system, bridging theoretical concepts with real-world deployment and observability practices in modern distributed systems.

---
# 🧩 Section 1: Prerequisites

This section ensures your system is fully ready before running the project.
Follow every step carefully and verify each tool.

---

# 1. System Requirements

### ✅ Operating System

* Windows 10 or Windows 11 (64-bit)

### ✅ Terminal

* Use **Git Bash** (recommended)

  * Comes with Git installation

### ✅ Code Editor (Optional)

* Recommended: **Zed Editor**
* You can also use:

  * VS Code
  * Notepad++

---

# 2. Required Tools & Installations

Install each tool **one by one** and verify after installation.

---

## 🔹 2.1 Git

**What it is:**
Used to download (clone) the project from GitHub.

**Download:**
👉 [https://git-scm.com/download/win](https://git-scm.com/download/win)

**Installation Steps:**

1. Run the installer
2. Keep all default settings
3. Finish installation

**Verify (Git Bash):**

```bash
git --version
```

✅ Expected output:

```
git version 2.x.x
```

---

## 🔹 2.2 AWS CLI

**What it is:**
Lets your computer communicate with AWS (create resources, manage EKS, etc.)

**Download:**
👉 [https://aws.amazon.com/cli/](https://aws.amazon.com/cli/)

**Installation Steps:**

1. Download Windows installer (.msi)
2. Run installer → Next → Finish

**Verify:**

```bash
aws --version
```

✅ Expected:

```
aws-cli/2.x.x Python/3.x ...
```

---

## 🔹 2.3 kubectl

**What it is:**
Command-line tool to control Kubernetes (EKS cluster).

**Download:**
👉 [https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

**Easy Install (Recommended):**

1. Download `kubectl.exe`
2. Place it in:

```
C:\kubectl\
```

3. Add this folder to **Environment Variables → PATH**

**Verify:**

```bash
kubectl version --client
```

---

## 🔹 2.4 eksctl

**What it is:**
CLI tool for managing EKS clusters (used indirectly in project).

**Download:**
👉 [https://eksctl.io/installation/](https://eksctl.io/installation/)

**Installation (Windows):**

1. Download `.zip`
2. Extract `eksctl.exe`
3. Place in:

```
C:\eksctl\
```

4. Add to PATH

**Verify:**

```bash
eksctl version
```

---

## 🔹 2.5 Docker Desktop

**What it is:**
Used to build and run containers (FastAPI + website).

**Download:**
👉 [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

**Installation Steps:**

1. Install Docker Desktop
2. Enable **WSL 2** when prompted
3. Restart system if required

**Verify:**

```bash
docker --version
```

Also check:

```bash
docker ps
```

✅ Should not give errors

---

## 🔹 2.6 Terraform

**What it is:**
Used to create AWS infrastructure automatically.

**Download:**
👉 [https://developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)

**Installation Steps:**

1. Download Windows zip
2. Extract `terraform.exe`
3. Place in:

```
C:\terraform\
```

4. Add to PATH

**Verify:**

```bash
terraform -version
```

---

## 🔹 2.7 Helm

**What it is:**
Package manager for Kubernetes (used to deploy apps and monitoring).

**Download:**
👉 [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)

**Installation (Windows):**

1. Download zip
2. Extract `helm.exe`
3. Place in:

```
C:\helm\
```

4. Add to PATH

**Verify:**

```bash
helm version
```

---

# 3. AWS Account Setup

---

## 🔹 3.1 Create AWS Account

👉 [https://aws.amazon.com/](https://aws.amazon.com/)

* Sign up with email
* Add billing details
* Choose **Basic (Free Tier)**

---

## 🔹 3.2 Create IAM User

1. Go to **IAM Dashboard**
2. Click **Users → Create User**
3. Username:

```
eks-admin
```

4. Enable:
   ✅ Programmatic access

---

## 🔹 3.3 Attach Permissions

Attach this policy:

```
AdministratorAccess
```

⚠️ This is for learning purposes only.

---

## 🔹 3.4 Create Access Keys

After user creation:

* Download or copy:

  * Access Key ID
  * Secret Access Key

---

## 🔹 3.5 Configure AWS CLI

Run in Git Bash:

```bash
aws configure
```

Enter:

```
AWS Access Key ID: <your key>
AWS Secret Access Key: <your secret>
Default region name: us-east-1
Default output format: json
```

---

## 🔹 3.6 Verify AWS Setup

```bash
aws sts get-caller-identity
```

✅ Expected: JSON output with your account info

---

# 4. GitHub Setup

---

## 🔹 4.1 Install GitHub (Already done via Git)

---

## 🔹 4.2 Clone Repository

```bash
git clone https://github.com/githubabhay2003/BTech-Major-Project-Cloud-Native-Observability-EKS.git
```

```bash
cd BTech-Major-Project-Cloud-Native-Observability-EKS
```

---

## 🔹 4.3 GitHub Actions Setup

### Important: Enable Actions

1. Open repo on GitHub
2. Go to **Actions tab**
3. Click:

```
Enable workflows
```

---

## 🔹 4.4 Required Permissions

Ensure:

* Repository is **not restricted**
* Actions are allowed to run

Settings → Actions → General:

* Allow all actions

---

## 🔹 4.5 No Secrets Needed

✅ This project uses:

* AWS OIDC (already configured in Terraform)

So:
👉 No GitHub secrets required

---

# 5. ⚠️ AWS Cost Warning (IMPORTANT)

This project uses **real AWS infrastructure**.

### ❗ Not Fully Free Tier

These services may incur charges:

| Service             | Cost Risk                               |
| ------------------- | --------------------------------------- |
| EKS Cluster         | ~$0.10/hour                             |
| EC2 Nodes           | Charged per instance                    |
| NAT Gateway         | Expensive (~$30+/month if left running) |
| Load Balancer (ELB) | Charged hourly                          |
| Data Transfer       | Additional charges                      |

---

## 🚨 Key Advice

* Run the project only for testing
* **Destroy everything after use** (you will do this later)
* Do NOT leave resources running overnight

---

## 💡 Estimated Cost (Short Usage)

* 1–2 hours usage → small cost (~$1–$3)
* Long-running → can become expensive

---

## ✅ Best Practice

After testing:
👉 Always run the **Destroy Guide**

---
# 🚀 Section 2: Project Setup (Rebuild Guide)

This section will **build the entire system from scratch** on AWS.

Follow each step **in exact order**. Do not skip anything.

---

# 🔷 STEP 1: Provision Infrastructure (Terraform – Infra Layer)

This creates:

* VPC (network)
* EKS cluster
* IAM roles
* ECR (container registry)
* Bastion host

---

## 📂 Navigate to Infra Directory

Open **Git Bash**:

```bash
cd BTech-Major-Project-Cloud-Native-Observability-EKS/terraform/infra
```

---

## ⚙️ Initialize Terraform

```bash
terraform init
```

✅ Expected:

* Providers downloaded
* Backend configured (S3)

---

## 🔍 Validate Configuration

```bash
terraform validate
```

✅ Expected:

```bash
Success! The configuration is valid.
```

---

## 📊 Preview Infrastructure

```bash
terraform plan
```

👉 This shows what AWS resources will be created

---

## 🚀 Apply (Create Infrastructure)

```bash
terraform apply -auto-approve
```

⏳ This may take **10–20 minutes**

---

## ✅ Verify EKS Cluster

```bash
aws eks list-clusters
```

✅ Expected output:

```bash
eks-observability-cluster
```

---

# 🔷 STEP 2: Configure Kubernetes Access

This connects your local machine to the EKS cluster.

---

## 🔗 Update kubeconfig

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-observability-cluster
```

---

## ✅ Verify Cluster Access

```bash
kubectl get nodes
```

⏳ Wait until nodes are ready

✅ Expected:

```bash
STATUS: Ready
```

---

# 🔷 STEP 3: Deploy Platform Layer (Terraform Apps)

This installs:

* Ingress Controller
* Prometheus + Grafana + Alertmanager
* Blackbox exporter
* Observability configs

---

## 📂 Navigate to Apps Directory

```bash
cd ../apps
```

---

## ⚠️ IMPORTANT: Install Monitoring First

Run this EXACT command:

```bash
terraform apply \
  -target=module.observability.kubernetes_namespace_v1.monitoring \
  -target=module.observability.helm_release.kube_prometheus_stack \
  -target=module.observability.helm_release.prometheus_blackbox_exporter \
  -auto-approve
```

⏳ Takes ~5–10 minutes

---

## ✅ Verify CRDs (Critical Step)

```bash
kubectl get crd | grep monitoring.coreos.com
```

✅ Expected:

* prometheusrules
* servicemonitors
* probes

---

## 🚀 Apply Full Apps Layer

```bash
terraform apply -auto-approve
```

---

## ✅ Verify Pods

```bash
kubectl get pods -A
```

✅ You should see:

* ingress-nginx
* prometheus
* grafana
* alertmanager

---

# 🔷 STEP 4: Verify Ingress Controller

```bash
kubectl get svc -n ingress-nginx
```

✅ Look for:

```bash
EXTERNAL-IP: <something.amazonaws.com>
```

📌 This is your **ELB URL**

---

# 🔷 STEP 5: Deploy Applications (CI/CD)

This step triggers:

* Docker build
* Push to ECR
* Helm deployment to EKS

---

## 🔁 Trigger GitHub Actions

```bash
git commit --allow-empty -m "trigger deployment"
git push
```

---

## 🔍 Monitor Deployment

1. Go to your GitHub repo
2. Click **Actions tab**
3. Open latest workflow

✅ Wait until:

```bash
All steps = green ✔
```

---

# 🔷 STEP 6: Verify Application Deployment

Run:

```bash
kubectl get pods
kubectl get deployments
kubectl get ingress -A
```

---

## ✅ Expected

You should see:

* fastapi-app running
* website running
* ingress resources created

---

# 🔷 STEP 7: Access the Application

---

## 🌐 Get ELB URL

```bash
kubectl get svc -n ingress-nginx
```

Copy the **EXTERNAL-IP**

---

## 🔗 Test URLs

Replace `<ELB>` with your value:

| Path                      | Service      |
| ------------------------- | ------------ |
| http://<ELB>/             | Website      |
| http://<ELB>/api          | FastAPI      |
| http://<ELB>/grafana      | Grafana      |
| http://<ELB>/prometheus   | Prometheus   |
| http://<ELB>/alertmanager | Alertmanager |

---

## ✅ Expected Behavior

* Website loads homepage
* `/api` returns JSON
* Grafana dashboard opens
* Prometheus UI loads

---

# 🔷 STEP 8: Test Observability (VERY IMPORTANT)

---

## 🔻 Simulate FastAPI Failure

```bash
kubectl scale deployment fastapi-app --replicas=0
```

⏳ Wait 30–60 seconds

👉 Check Prometheus alerts:

* FastAPI should show alerts

---

## 🔁 Restore FastAPI

```bash
kubectl scale deployment fastapi-app --replicas=2
```

---

## 🔻 Simulate Website Failure

```bash
kubectl scale deployment website --replicas=0
```

⏳ Wait 30–60 seconds

---

## ✅ Expected Alert

In Prometheus:

```bash
WebsiteDown → FIRING 🔴
```

---

## 🔁 Restore Website

```bash
kubectl scale deployment website --replicas=2
```

---
# ▶️ Section 3: Running the Project & Verification

At this point, your system is deployed.
This section helps you **confirm everything is working correctly** and understand how to interact with it.

---

# 🔷 1. Quick Health Check (System Status)

Run these commands in **Git Bash**:

```bash id="h0j2cf"
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

---

## ✅ What You Should See

### Nodes

* Status: `Ready`

### Pods

* Running pods for:

  * `fastapi`
  * `website`
  * `ingress-nginx`
  * `prometheus`
  * `grafana`
  * `alertmanager`

### Services

* One service with:

  ```bash
  TYPE: LoadBalancer
  ```

---

# 🔷 2. Access Your Application

---

## 🌐 Get Public URL (ELB)

```bash id="0hlg4m"
kubectl get svc -n ingress-nginx
```

Copy the **EXTERNAL-IP** (looks like a long AWS URL)

---

## 🔗 Open in Browser

Use these URLs:

| URL                         | What You See      |
| --------------------------- | ----------------- |
| `http://<ELB>/`             | Website homepage  |
| `http://<ELB>/api`          | FastAPI response  |
| `http://<ELB>/grafana`      | Grafana dashboard |
| `http://<ELB>/prometheus`   | Prometheus UI     |
| `http://<ELB>/alertmanager` | Alertmanager UI   |

---

## ✅ Expected Results

* Website loads with project info
* `/api` returns JSON like:

```json
{ "message": "FastAPI Observability App" }
```

* Grafana opens (no login needed or uses default creds)
* Prometheus shows targets and metrics
* Alertmanager UI loads

---

# 🔷 3. Verify Metrics Collection

---

## 📊 Check Prometheus Targets

1. Open:

```bash id="p3u6o7"
http://<ELB>/prometheus
```

2. Click:

```bash
Status → Targets
```

---

## ✅ Expected

* FastAPI target = **UP**
* Kubernetes targets = **UP**

---

# 🔷 4. View Grafana Dashboard

---

## 📈 Open Grafana

```bash id="1u6yfe"
http://<ELB>/grafana
```

---

## 🔍 Navigate

* Go to **Dashboards**
* Open:

```bash
FastAPI – Golden Signals
```

---

## ✅ You Should See

* Request rate (RPS)
* Error rate
* Latency (P95, P99)
* CPU usage
* Memory usage

---

# 🔷 5. Test Alerts (System Validation)

This confirms observability is working correctly.

---

## 🔻 Test 1: FastAPI Down

```bash id="otn4n2"
kubectl scale deployment fastapi-app --replicas=0
```

⏳ Wait ~1 minute

---

### 🔍 Check Alert

Open:

```bash id="3x0o2o"
http://<ELB>/prometheus
```

Go to:

```bash
Alerts
```

---

### ✅ Expected

* Alert:

```bash
FastAPIDown → FIRING 🔴
```

---

## 🔁 Restore FastAPI

```bash id="xq1nmk"
kubectl scale deployment fastapi-app --replicas=2
```

---

## 🔻 Test 2: Website Down

```bash id="r3c1s5"
kubectl scale deployment website --replicas=0
```

⏳ Wait ~1 minute

---

### ✅ Expected

```bash
WebsiteDown → FIRING 🔴
```

---

## 🔁 Restore Website

```bash id="p9k3bz"
kubectl scale deployment website --replicas=2
```

---

# 🔷 6. Email Alert Verification

If SMTP works:

* Alerts will be sent to:

```bash
youremail@gmail.com
```

---

## ⚠️ Note

* Email may take time or fail depending on Gmail restrictions
* This does not affect system functionality

---

# 🔷 7. Common Checks (If Something Looks Wrong)

---

## ❌ Pods Not Running

```bash id="s8b9kz"
kubectl get pods -A
```

👉 Look for:

* `CrashLoopBackOff`
* `Pending`

---

## ❌ No External IP

```bash id="p2k7df"
kubectl get svc -n ingress-nginx
```

👉 If `<pending>`:

* Wait 2–5 minutes
* AWS is provisioning ELB

---

## ❌ API Not Working

```bash id="zt4y6m"
kubectl get pods
```

👉 Ensure:

* fastapi pod is running

---
# 🧹 Section 4: Teardown (Destroy Guide)

This section will **completely remove all AWS resources** created by the project.

⚠️ Follow steps **exactly in order** to avoid:

* Stuck AWS resources
* Unexpected costs
* Terraform errors

---

# 🔷 STEP 1: Delete Kubernetes LoadBalancers & Ingress

## 🎯 Why this is important

Kubernetes creates AWS resources automatically:

* ELB (Load Balancer)
* ENI (Network Interfaces)
* Security Groups

If not removed first → Terraform destroy may fail.

---

## 🧹 Run Cleanup Commands

```bash id="p6o0kp"
kubectl delete ingress --all -A
```

```bash id="d2o4b7"
kubectl delete svc -A --field-selector spec.type=LoadBalancer
```

---

## ⏳ WAIT (VERY IMPORTANT)

```bash id="zq5k8x"
sleep 60
```

👉 This gives AWS time to delete:

* Load balancers
* Network interfaces

---

## ✅ Verify Cleanup

```bash id="j4x7zn"
kubectl get ingress -A
```

```bash id="k1v9rm"
kubectl get svc -A | grep LoadBalancer
```

---

### ✅ Expected Output

```bash id="f8c2qy"
No resources found
```

---

# 🔷 STEP 2: Verify AWS Load Balancers (CRITICAL)

Run:

```bash id="z9h2xc"
aws elb describe-load-balancers --region us-east-1
```

---

## ✅ Expected

* Empty or no active load balancers

---

## ❗ If Load Balancer Still Exists

👉 Wait another 2–3 minutes and check again

---

# 🔷 STEP 3: Destroy Apps Layer (Terraform)

This removes:

* Prometheus
* Grafana
* Alertmanager
* Ingress controller
* All Kubernetes resources

---

## 📂 Navigate to Apps Directory

```bash id="1xv7bq"
cd BTech-Major-Project-Cloud-Native-Observability-EKS/terraform/apps
```

---

## 💥 Destroy Apps

```bash id="t6m4wp"
terraform destroy -auto-approve
```

⏳ Takes ~5–10 minutes

---

# 🔷 STEP 4: Destroy Infrastructure Layer

This removes:

* EKS cluster
* EC2 nodes
* VPC, subnets
* NAT Gateway
* IAM roles
* ECR

---

## 📂 Navigate to Infra Directory

```bash id="c3k9yt"
cd ../infra
```

---

## 💥 Destroy Infrastructure

```bash id="b8p2ns"
terraform destroy -auto-approve
```

⏳ Takes ~10–20 minutes

---

# 🔷 STEP 5: Final AWS Verification

Make sure **nothing is left running**.

---

## 🔍 Check VPCs

```bash id="u7f3hj"
aws ec2 describe-vpcs
```

---

## 🔍 Check Subnets

```bash id="r2y6kd"
aws ec2 describe-subnets
```

---

## 🔍 Check Load Balancers

```bash id="n5m1qp"
aws elb describe-load-balancers
```

---

## 🔍 Check Network Interfaces

```bash id="v8z4lt"
aws ec2 describe-network-interfaces
```

---

## ✅ Expected Result

* No resources related to this project
* Clean AWS account

---

# ⚠️ If Something Still Exists

* Wait a few minutes (AWS cleanup delay)
* Re-run the commands
* Check AWS Console manually:

  * EC2 → Load Balancers
  * EC2 → Network Interfaces

---

# 💡 Final Safety Check

Make sure:

* No EKS cluster
* No EC2 instances
* No NAT Gateway
* No Load Balancer

---

# ✅ Teardown Complete

You have successfully:

* Removed all Kubernetes resources
* Deleted all AWS infrastructure
* Prevented ongoing costs

---
