##  CI/CD Pipeline

### **Overview**

The project uses a **CI/CD pipeline (Continuous Integration and Continuous Deployment)** implemented with **GitHub Actions** to automate the entire application deployment process.

This pipeline ensures that every code change is:

* Automatically built
* Tested (implicitly via build success)
* Deployed to the Kubernetes cluster

👉 This reduces manual effort and improves reliability.

---

## **Key Components of the Pipeline**

| **Component**                               | **Role**                                     |
| ------------------------------------------- | -------------------------------------------- |
| **GitHub**                                  | Source code repository and trigger point     |
| **GitHub Actions**                          | Executes the CI/CD workflow                  |
| **Docker**                                  | Builds container images                      |
| **Amazon ECR (Elastic Container Registry)** | Stores Docker images                         |
| **Amazon EKS**                              | Runs the deployed applications               |
| **Helm**                                    | Manages Kubernetes deployments               |
| **OIDC (OpenID Connect)**                   | Secure authentication between GitHub and AWS |

---

## **Pipeline Trigger**

* The pipeline is triggered when:

  * Code is pushed to the **main branch**

👉 This ensures continuous deployment of the latest changes

---

## **Step-by-Step Pipeline Workflow**

### **1. Code Checkout**

* GitHub Actions fetches the latest code from the repository

---

### **2. AWS Authentication (OIDC)**

* Uses **OpenID Connect (OIDC)** to securely assume an AWS IAM role
* No hardcoded credentials are required

👉 Enhances security and follows best practices

---

### **3. Docker Image Build**

Two images are built:

* **FastAPI Application Image**
* **Website Image**

Each image is:

* Built using its respective Dockerfile
* Tagged with the **commit SHA** (unique identifier)

---

### **4. Push Images to Amazon ECR**

* Images are pushed to:

  * Amazon Elastic Container Registry (ECR)

👉 Makes images available for deployment in Kubernetes

---

### **5. Connect to EKS Cluster**

* The pipeline updates **kubeconfig** using AWS CLI
* This allows GitHub Actions to interact with the Kubernetes cluster

---

### **6. Helm Deployment**

* Applications are deployed using **Helm charts**

* Commands used:

  * `helm upgrade --install`

* Dynamic values passed:

  * Image repository
  * Image tag (commit SHA)

👉 Enables versioned and repeatable deployments

---

## **Deployment Strategy**

* Uses **rolling updates** (default Kubernetes behavior)
* Ensures:

  * Zero downtime
  * Smooth updates

---

## **Pipeline Flow Summary**

1. Developer pushes code to GitHub
2. GitHub Actions pipeline starts
3. Docker images are built
4. Images are pushed to ECR
5. Helm deploys applications to EKS
6. Updated application becomes live

---

### **Key Advantages**

* 🔄 **Automation** → No manual deployment required
* 🔐 **Security** → Uses OIDC instead of static credentials
* 📦 **Version Control** → Image tagging with commit SHA
* ⚡ **Fast Deployment** → Changes go live quickly
* 🔁 **Consistency** → Same process for every deployment

---

### **In Simple Words**

> The CI/CD pipeline automatically takes your code, turns it into a running application, and deploys it to the cloud every time you make a change.

---
