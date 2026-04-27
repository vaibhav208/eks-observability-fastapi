##  Infrastructure Design (Terraform)

### **Overview**

The infrastructure for this project is designed using **Terraform**, an **Infrastructure as Code (IaC)** tool that allows cloud resources to be defined, provisioned, and managed through code.

This approach ensures:

* Consistency across environments
* Automated provisioning
* Easy scalability and maintenance

The infrastructure is organized into two main layers:

1. **Core Infrastructure (`infra`)**
2. **Application & Platform Layer (`apps`)**

---

## **1. Core Infrastructure Layer (`terraform/infra`)**

This layer is responsible for creating the **foundation of the system on AWS**.

---

### **a. Networking (VPC Setup)**

A custom **Virtual Private Cloud (VPC)** is created with:

* **Public Subnets**

  * Used for:

    * Internet Gateway
    * NAT Gateway
    * Bastion Host

* **Private Subnets**

  * Used for:

    * EKS cluster
    * Worker nodes

* **Internet Gateway**

  * Allows external traffic into the VPC

* **NAT Gateway**

  * Allows private resources to access the internet securely

👉 This ensures **secure isolation of internal services**

---

### **b. Amazon EKS Cluster**

* A managed Kubernetes cluster is created using **Amazon EKS**
* Includes:

  * Control plane (managed by AWS)
  * Node group (EC2 instances for workloads)

**Node Group Configuration:**

* Auto-scaling enabled (min, max, desired capacity)
* Runs application workloads

---

### **c. IAM (Identity and Access Management)**

IAM roles are created for secure access:

* **EKS Cluster Role**
* **Worker Node Role**
* **GitHub Actions Role (OIDC-based)**
* **Bastion Host Role**

👉 Enables **secure, role-based access control**

---

### **d. Bastion Host**

* An EC2 instance deployed in a public subnet
* Used for:

  * Secure access to the Kubernetes cluster
  * Running administrative commands (kubectl, helm)

---

### **e. Amazon ECR (Elastic Container Registry)**

* Stores Docker images for:

  * FastAPI application
  * Website

👉 Acts as a central image repository for deployments

---

### **f. Remote State Management**

Terraform state is managed using:

* **Amazon S3**

  * Stores state files

* **Amazon DynamoDB**

  * Provides state locking

👉 Prevents conflicts during concurrent deployments

---

## **2. Application & Platform Layer (`terraform/apps`)**

This layer configures and deploys **Kubernetes-based services** on the EKS cluster.

---

### **a. Kubernetes Access Configuration**

* Uses remote state from `infra` to:

  * Connect to EKS cluster
  * Configure authentication

* Updates **aws-auth ConfigMap** to:

  * Grant access to nodes
  * Allow GitHub Actions to deploy

---

### **b. NGINX Ingress Controller**

* Installed using **Helm**
* Configured as:

  * **LoadBalancer service**
* Acts as:

  * Entry point for all external traffic

---

### **c. Observability Module**

Deploys the monitoring stack:

* **Prometheus + Grafana + Alertmanager**
* **Blackbox Exporter**

Also configures:

* Dashboards
* Alert rules
* Metrics scraping

---

### **d. Observability Routing**

* Uses:

  * **ExternalName services**
  * **Ingress resources**

* Exposes:

  * Grafana → `/grafana`
  * Prometheus → `/prometheus`
  * Alertmanager → `/alertmanager`

👉 Enables centralized access to monitoring tools

---

## **Modular Design Approach**

The Terraform code is structured into reusable modules:

* `network` → VPC and subnets
* `iam` → Roles and permissions
* `eks` → Kubernetes cluster
* `bastion` → Admin access
* `ecr` → Container registry
* `observability` → Monitoring stack
* `ingress-nginx` → Traffic routing

👉 Improves maintainability and scalability

---

## **Infrastructure Workflow**

1. Terraform provisions AWS infrastructure
2. EKS cluster is created and configured
3. Kubernetes providers connect to the cluster
4. Helm deploys platform components
5. Applications are later deployed via CI/CD

---

### **Key Design Principles**

* **Infrastructure as Code** → Everything is version-controlled
* **Modularity** → Components are reusable and independent
* **Security** → Private subnets and IAM roles
* **Scalability** → EKS + node groups
* **Automation** → Minimal manual intervention

---

### **In Simple Words**

> Terraform builds the entire cloud environment from scratch, ensuring everything is automated, secure, and ready for application deployment.

---
