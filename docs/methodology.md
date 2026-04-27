##  Methodology & Workflow

### **Overview**

The methodology of this project follows a **DevOps-driven, cloud-native approach**, where the entire lifecycle of the application is:

* Designed
* Built
* Deployed
* Monitored
* Continuously improved

This ensures automation, consistency, and real-time visibility.

---

## **Step-by-Step Workflow**

The complete workflow can be divided into the following stages:

---

### **1. Infrastructure Provisioning**

* Infrastructure is defined using **Terraform (Infrastructure as Code - IaC)**
* Key resources created:

  * Virtual Private Cloud (VPC)
  * Subnets (public and private)
  * Amazon EKS cluster
  * IAM roles and permissions

👉 This step ensures that the environment is **consistent and reproducible**

---

### **2. Application Development**

* Backend developed using **FastAPI**
* Frontend created as a **static website (HTML + NGINX)**
* Applications are designed to:

  * Be lightweight
  * Expose health and metrics endpoints

---

### **3. Containerization**

* Applications are packaged into **Docker containers**
* Each service has its own Docker image:

  * FastAPI image
  * Website image

👉 This ensures portability across environments

---

### **4. Version Control & Code Management**

* Source code is managed using **GitHub**
* Developers push changes to the repository

👉 Every code change becomes a trigger for automation

---

### **5. CI/CD Pipeline Execution**

* **GitHub Actions** automatically:

  1. Builds Docker images
  2. Tags images using commit SHA
  3. Pushes images to Amazon ECR
  4. Deploys applications using Helm

👉 This eliminates manual deployment and reduces errors

---

### **6. Kubernetes Deployment**

* Applications are deployed to **Amazon EKS** using **Helm charts**
* Kubernetes manages:

  * Pods (application instances)
  * Services (network access)
  * Ingress (external routing)

👉 Ensures scalability and self-healing capabilities

---

### **7. Traffic Routing**

* **NGINX Ingress Controller** routes incoming traffic:

  * `/` → Website
  * `/api` → FastAPI

👉 Provides a unified entry point for all services

---

### **8. Monitoring & Observability**

* **Prometheus** collects metrics from:

  * FastAPI (`/metrics`)
  * Kubernetes resources

* **Grafana** visualizes metrics through dashboards

👉 Enables real-time performance tracking

---

### **9. Alerting Mechanism**

* **Prometheus** evaluates alert rules
* Alerts are sent to **Alertmanager**
* Alertmanager sends notifications via **email**

👉 Ensures quick response to system issues

---

### **10. External Health Monitoring**

* **Blackbox Exporter** periodically checks:

  * Website availability
* Alerts are triggered if the service is unreachable

---

## **Workflow Summary (Simplified Flow)**

1. Developer pushes code → GitHub
2. CI/CD pipeline builds & deploys application
3. Application runs on EKS
4. Prometheus collects metrics
5. Grafana displays system performance
6. Alerts triggered when issues occur

---

### **Key Methodological Approach**

* **Automation First** → Reduce manual work
* **Observability by Design** → Monitoring built into the system
* **Modular Architecture** → Independent components
* **Continuous Feedback Loop** → Monitor → Detect → Improve

---

### **In Simple Words**

> The project follows a workflow where everything is automated, continuously monitored, and designed to quickly detect and respond to issues.

---
