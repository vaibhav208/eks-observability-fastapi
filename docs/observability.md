##  Observability Implementation

### **Overview**

Observability is a key part of this project. It ensures that the system is not only running, but also **measurable, visible, and understandable in real time**.

The project implements observability using three main pillars:

* **Metrics** → What is happening in the system
* **Visualization** → How the system is performing
* **Alerting** → When something goes wrong

This is achieved using:

* **Prometheus**
* **Grafana**
* **Alertmanager**

---

## **1. Metrics Collection (Prometheus)**

### **What is Prometheus?**

Prometheus is an open-source monitoring system that:

* Collects metrics from applications
* Stores them as time-series data
* Allows querying using PromQL (Prometheus Query Language)

---

### **How Metrics are Collected**

#### **FastAPI Instrumentation**

* The FastAPI application is instrumented using:

  * `prometheus-fastapi-instrumentator`

* It exposes a `/metrics` endpoint automatically

👉 This endpoint provides data such as:

* Request count
* Response status codes
* Request latency

---

#### **Service Monitoring (ServiceMonitor)**

* A **ServiceMonitor** resource is created in Kubernetes
* It tells Prometheus:

  * Which service to monitor
  * Where to scrape metrics from

**Configuration Highlights:**

* Scrape interval: 15 seconds
* Target: FastAPI service

---

#### **Kubernetes Metrics**

Prometheus also collects:

* CPU usage
* Memory usage
* Pod and node metrics

---

## **2. Visualization (Grafana)**

### **What is Grafana?**

Grafana is a visualization tool that:

* Connects to Prometheus
* Displays data using dashboards

---

### **Custom Dashboard (Golden Signals)**

A custom dashboard is created to monitor key system metrics:

#### **Golden Signals Covered**

| **Metric**             | **Description**               |
| ---------------------- | ----------------------------- |
| **Traffic (RPS)**      | Number of requests per second |
| **Error Rate**         | Rate of failed (5xx) requests |
| **Latency (P95, P99)** | Response time distribution    |
| **CPU Usage**          | Resource utilization          |
| **Memory Usage**       | Memory consumption            |

👉 These metrics provide a **complete view of system health**

---

### **Dashboard Deployment**

* Dashboards are defined as JSON
* Stored in a Kubernetes **ConfigMap**
* Automatically loaded into Grafana using a sidecar

---

## **3. External Monitoring (Blackbox Exporter)**

### **Purpose**

* Monitors **service availability from outside the system**

---

### **How it Works**

* Sends HTTP requests to the website

* Measures:

  * Response success
  * Availability

* Uses a **Probe resource** to define:

  * Target URL
  * Check interval

---

## **4. Alerting Integration (Overview)**

* Prometheus evaluates predefined rules
* Alerts are sent to **Alertmanager**
* Notifications are delivered via email

👉 Detailed alert logic is covered in the next section

---

## **5. Observability Flow**

1. FastAPI exposes metrics (`/metrics`)
2. Prometheus scrapes metrics periodically
3. Data is stored as time-series
4. Grafana queries and visualizes data
5. Alerts are triggered if thresholds are exceeded

---

## **Key Design Principles**

* **Built-in Observability** → Metrics integrated into the application
* **Real-Time Monitoring** → Continuous data collection
* **Actionable Insights** → Dashboards + alerts
* **External Validation** → Blackbox monitoring

---

### **In Simple Words**

> Observability in this project ensures that you can see how your system is performing, understand what is happening inside it, and get alerted immediately when something goes wrong.

---
