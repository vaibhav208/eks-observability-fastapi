## 🏗️ Architecture Overview

### **Architecture Diagram**

<p align="center">
  <img src="https://raw.githubusercontent.com/githubabhay2003/BTech-Major-Project-Cloud-Native-Observability-EKS/main/docs/images/architecture-image.png" width="100%"><br>
  <b>Figure:</b> <i>End-to-End Architecture of the Cloud-Native Observability Platform on Amazon EKS</i>
</p>

---

### **High-Level Architecture Description**

The system is designed as a **layered cloud-native architecture**, where each layer has a specific responsibility. This ensures modularity, scalability, and ease of management.

The architecture can be understood in **four main layers**:

---

## **1. External Layer (User Interaction)**

* Users access the system through a **web browser**
* Requests are sent to the application via the internet
* Developers push code changes to **GitHub**, triggering the deployment pipeline

👉 This layer represents both **end-users** and **developers**

---

## **2. CI/CD Layer (Automation Layer)**

This layer handles **Continuous Integration and Continuous Deployment (CI/CD)**.

### Key Components:

* **GitHub Actions**
* **OIDC (OpenID Connect) Authentication**
* **Docker**
* **Amazon ECR (Elastic Container Registry)**
* **Helm**

### Workflow:

1. Developer pushes code to GitHub
2. GitHub Actions pipeline is triggered
3. Docker images are built for:

   * FastAPI backend
   * Website
4. Images are pushed to Amazon ECR
5. Helm deploys updated applications to EKS

👉 This ensures **fully automated deployments without manual intervention**

---

## **3. AWS Infrastructure Layer**

This is the **core cloud environment** where everything runs.

### **Networking (Amazon VPC)**

* **Public Subnets**

  * Internet Gateway (external access)
  * NAT Gateway (outbound internet for private resources)
  * Bastion Host (secure admin access)

* **Private Subnets**

  * Amazon EKS Cluster
  * Worker Nodes (Node Group)

👉 Ensures **secure and isolated deployment of workloads**

---

### **EKS Cluster (Kubernetes Layer)**

Inside the cluster:

#### **Ingress Controller**

* **NGINX Ingress Controller**
* Acts as a **single entry point**
* Routes traffic based on paths:

  * `/` → Website
  * `/api` → FastAPI

---

### **Application Workloads**

#### **1. Static Website**

* Deployed as a Kubernetes Deployment
* Exposed via a Service on port 80

#### **2. FastAPI Backend**

* Deployed as a Kubernetes Deployment
* Exposes:

  * `/api` → application endpoints
  * `/health` → liveness/readiness checks
  * `/metrics` → Prometheus metrics

---

### **IAM Roles & State Management**

* IAM roles are used for:

  * EKS Cluster
  * Node Group
  * GitHub Actions (OIDC-based access)
  * Bastion Host

* Terraform state:

  * Stored in **Amazon S3**
  * Locked using **DynamoDB**

👉 Ensures **secure access control and consistent infrastructure state**

---

## **4. Observability & Monitoring Layer**

This layer provides **complete visibility into system behavior**.

---

### **Monitoring Components**

#### **Prometheus**

* Collects metrics from:

  * FastAPI (`/metrics`)
  * Kubernetes resources
* Stores time-series data

---

#### **Grafana**

* Visualizes metrics using dashboards
* Displays:

  * Request rate
  * Error rate
  * Latency (P95, P99)
  * CPU and memory usage

---

#### **Alertmanager**

* Receives alerts from Prometheus
* Sends notifications via **email**

---

#### **Blackbox Exporter**

* Monitors external availability of the website
* Simulates real user access

---

### **Custom Monitoring Resources**

* **ServiceMonitor** → connects Prometheus to FastAPI
* **PrometheusRule** → defines alert conditions
* **Probe** → monitors website uptime

---

## **End-to-End Flow (Simplified)**

1. User sends request → Ingress Controller
2. Request routed to:

   * Website or FastAPI
3. FastAPI exposes metrics
4. Prometheus collects metrics
5. Grafana visualizes data
6. Alerts triggered via Alertmanager if thresholds exceed

---

### **Architecture Summary**

> The architecture integrates infrastructure, deployment, application, and observability into a unified system where everything is automated, monitored, and easily accessible.

---
