##  Limitations

### **Overview**

While the project successfully demonstrates a complete cloud-native observability platform, it has certain limitations due to scope, design choices, and the academic nature of the implementation.

Understanding these limitations helps identify areas for improvement and future enhancement.

---

## **Key Limitations**

---

### **1. Not Fully Production-Hardened**

* The system is designed for learning and demonstration
* Missing advanced production features such as:

  * Fine-grained security policies
  * High availability configurations across multiple regions

👉 Suitable for **educational and prototype use**, not full-scale production

---

### **2. Limited Security Implementation**

* Some configurations are simplified:

  * IAM roles may have broad permissions (for ease of setup)
  * Credentials (e.g., SMTP, Grafana) may not use secure secret storage

👉 Needs improvement with:

* Kubernetes Secrets
* Role-based access control (RBAC) refinement

---

### **3. Cost Considerations**

* Uses real AWS services such as:

  * EKS
  * NAT Gateway
  * Load Balancer

* These services are **not fully free-tier eligible**

👉 Requires careful usage and teardown to avoid costs

---

### **4. Single Region Deployment**

* Deployed only in one AWS region (e.g., `us-east-1`)
* No multi-region failover or disaster recovery

👉 Limits system resilience in case of regional failures

---

### **5. Basic Alerting Strategy**

* Alerts cover key scenarios but are:

  * Not deeply tuned
  * May include noise (e.g., expected alerts in EKS)

👉 Needs refinement for:

* Alert prioritization
* Noise reduction

---

### **6. Limited Logging Implementation**

* Focus is mainly on **metrics-based observability**
* Centralized logging (e.g., ELK stack or Loki) is not implemented

👉 Limits ability to debug detailed application issues

---

### **7. Manual Testing for Failure Scenarios**

* Failure scenarios (e.g., scaling pods to zero) are tested manually
* No automated chaos testing or resilience testing

👉 Could be improved using:

* Chaos engineering tools

---

### **8. Simplified Frontend Application**

* Uses a basic static website
* No dynamic frontend framework or user interaction

👉 Focus is on infrastructure and observability rather than UI complexity

---

### **9. Limited Autoscaling Configuration**

* Kubernetes supports autoscaling, but:

  * Horizontal Pod Autoscaler (HPA) is not fully implemented

👉 Limits automatic scaling based on real-time load

---

### **10. Tight Coupling in Some Areas**

* Some components (Terraform, Helm, CI/CD) are closely integrated
* Changes in one layer may require updates in others

👉 Could be improved with better decoupling and abstraction

---

## **Summary**

> While the project effectively demonstrates modern DevOps and observability practices, it is intentionally simplified in certain areas to maintain clarity and feasibility within an academic scope.

---

### **In Simple Words**

> The system works well and shows real-world concepts, but it is not fully optimized for production environments and can be improved in areas like security, scalability, and advanced monitoring.

---
