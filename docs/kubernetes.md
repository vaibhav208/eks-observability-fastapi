##  Kubernetes Deployment (Helm)

### **Overview**

In this project, applications are deployed on Kubernetes using **Helm**, a package manager for Kubernetes that simplifies deployment and management of applications.

Helm allows us to:

* Define Kubernetes resources as reusable templates
* Manage configurations easily
* Perform upgrades and rollbacks efficiently

👉 This makes deployments **consistent, scalable, and maintainable**

---

## **What is Helm (Simple Explanation)**

Helm works like a package manager (similar to npm or apt), but for Kubernetes.

* A **Helm Chart** is a collection of Kubernetes YAML templates
* It allows dynamic configuration using values

---

## **Helm Charts Used in the Project**

The project uses two custom Helm charts:

| **Application** | **Chart Location** | **Purpose**                 |
| --------------- | ------------------ | --------------------------- |
| FastAPI Backend | `helm/fastapi`     | Deploys backend API service |
| Website         | `helm/website`     | Deploys static frontend     |

---

## **Key Kubernetes Resources Created**

Each Helm chart defines the following core resources:

---

### **1. Deployment**

* Manages application pods
* Ensures desired number of replicas are running

**FastAPI Example:**

* Multiple replicas for scalability
* Includes:

  * **Liveness Probe** → checks if app is alive
  * **Readiness Probe** → checks if app is ready to serve traffic

👉 Helps Kubernetes automatically recover from failures

---

### **2. Service**

* Exposes the application internally within the cluster
* Uses:

  * **ClusterIP** (internal access)

👉 Enables communication between services

---

### **3. Ingress**

* Provides external access to services via HTTP/HTTPS
* Managed by **NGINX Ingress Controller**

**Routing Rules:**

* `/` → Website
* `/api` → FastAPI backend

👉 Acts as a **single entry point** for users

---

## **Configuration Using Values.yaml**

Each Helm chart uses a `values.yaml` file to define:

* Number of replicas
* Container image details
* Ports
* Labels

Example:

* FastAPI runs on port **8000**
* Website runs on port **80**

👉 Allows easy customization without modifying templates

---

## **Dynamic Deployment via CI/CD**

During deployment, Helm receives dynamic values:

* Image repository (from ECR)
* Image tag (commit SHA)

This ensures:

* Every deployment uses the latest image
* Version tracking is maintained

---

## **Deployment Command**

The CI/CD pipeline uses:

```
helm upgrade --install <release-name> <chart-path>
```

This command:

* Installs the application if not present
* Upgrades it if already deployed

---

## **Deployment Workflow**

1. Helm reads chart templates
2. Values are injected dynamically
3. Kubernetes resources are created/updated
4. Pods are scheduled and started
5. Services and ingress expose the application

---

## **Key Benefits of Using Helm**

* 📦 **Reusability** → Templates can be reused across environments
* 🔄 **Easy Updates** → Upgrade without downtime
* ⚙️ **Configuration Management** → Centralized values
* 📊 **Scalability** → Easily adjust replicas
* 🔁 **Rollback Support** → Revert to previous versions

---

### **In Simple Words**

> Helm simplifies Kubernetes deployment by packaging everything into reusable templates, making application deployment fast, consistent, and easy to manage.

---
