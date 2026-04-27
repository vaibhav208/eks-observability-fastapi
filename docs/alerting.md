## Alerts & Monitoring Strategy

### **Overview**

The project implements a structured **monitoring and alerting strategy** to ensure that system issues are detected early and handled efficiently.

This strategy is built using:

* **Prometheus** → Evaluates conditions and generates alerts
* **Alertmanager** → Processes and sends notifications
* **Grafana** → Visualizes system health

---

## **1. Alerting Strategy Design**

The alerting system is designed around three key goals:

* 🔍 **Early Detection** → Identify issues before they impact users
* ⚠️ **Actionable Alerts** → Provide meaningful alerts, not noise
* 📩 **Timely Notifications** → Inform the team immediately

---

## **2. Types of Alerts Implemented**

### **A. Application-Level Alerts (FastAPI)**

These alerts monitor the health and performance of the backend service.

| **Alert Name**  | **Condition**           | **Purpose**             |
| --------------- | ----------------------- | ----------------------- |
| High Error Rate | Too many 5xx responses  | Detect backend failures |
| High Latency    | P95 latency > threshold | Detect slow responses   |
| Service Down    | No running replicas     | Detect complete outage  |

👉 Ensures the API is **available, fast, and reliable**

---

### **B. Website Availability Alerts**

* Uses **Blackbox Exporter** to simulate real user access
* Alert triggers when:

  * Website is not reachable via HTTP

👉 Ensures **end-user accessibility**

---

### **C. Infrastructure-Level Alerts (Kubernetes)**

These come from the **kube-prometheus-stack** and monitor cluster components.

However, some alerts behave differently in **Amazon EKS (Elastic Kubernetes Service)**.

---

## **3. Special Alerts in EKS (Important Understanding)**

Based on your provided document , some alerts appear even when the system is healthy.

---

### **1. KubeControllerManagerDown**

* **What it means:** Controller Manager is not detected
* **Reason:** In EKS, it is managed by AWS and not visible inside the cluster
* **Interpretation:**

  * ✅ Normal behavior
  * ❌ Not an actual failure

---

### **2. KubeSchedulerDown**

* **What it means:** Scheduler is not detected
* **Reason:** Also managed externally by AWS
* **Interpretation:**

  * ✅ Normal behavior
  * ❌ Not a real issue

---

### **3. Watchdog Alert**

* **What it means:** A test alert to verify alerting system health

* **Behavior:** Always active

* **Interpretation:**

  * ✅ Confirms alerting pipeline is working
  * ❗ Should NOT be disabled

---

### **Summary of These Alerts**

| **Alert**                 | **Meaning**                       | **Is it Normal?** | **Action**   |
| ------------------------- | --------------------------------- | ----------------- | ------------ |
| KubeControllerManagerDown | AWS-managed component not visible | Yes               | Ignore       |
| KubeSchedulerDown         | AWS-managed component not visible | Yes               | Ignore       |
| Watchdog                  | System health check               | Yes               | Keep enabled |

---

## **4. Alert Flow**

1. Prometheus continuously evaluates metrics
2. If a condition is met → alert is triggered
3. Alert is sent to **Alertmanager**
4. Alertmanager:

   * Groups alerts
   * Applies rules
   * Sends email notifications

---

## **5. Notification Configuration**

* Alerts are sent via **email (SMTP configuration)**
* Includes:

  * Alert name
  * Description
  * Severity level

👉 Ensures quick awareness of system issues

---

## **6. Alert Severity Levels**

* **Warning** → Performance issues (e.g., latency, error rate)
* **Critical** → Service down or unavailable

---

## **7. Monitoring Strategy Summary**

The monitoring system combines:

* 📊 **Metrics Monitoring** → Prometheus
* 📈 **Visualization** → Grafana
* 🚨 **Alerting** → Alertmanager
* 🌐 **External Checks** → Blackbox Exporter

---

### **Key Insight**

> Not all alerts indicate real problems — especially in managed environments like EKS. Understanding context is essential to avoid false alarms.

---

### **In Simple Words**

> The system continuously watches application performance and automatically alerts you when something goes wrong, while also filtering out expected behavior in managed cloud environments.

---
