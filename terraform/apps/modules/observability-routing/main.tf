resource "kubernetes_service_v1" "grafana_proxy" {
  metadata {
    name      = "grafana-proxy"
    namespace = "default"
  }

  spec {
    type          = "ExternalName"
    external_name = "kube-prometheus-stack-grafana.monitoring.svc.cluster.local"

    port {
      port     = 80
      protocol = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "prometheus_proxy" {
  metadata {
    name      = "prometheus-proxy"
    namespace = "default"
  }

  spec {
    type          = "ExternalName"
    external_name = "kube-prometheus-stack-prometheus.monitoring.svc.cluster.local"

    port {
      port     = 9090
      protocol = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "alertmanager_proxy" {
  metadata {
    name      = "alertmanager-proxy"
    namespace = "default"
  }

  spec {
    type          = "ExternalName"
    external_name = "kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local"

    port {
      port     = 9093
      protocol = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "observability_ingress_core" {
  metadata {
    name      = "observability-ingress-core"
    namespace = "default"

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/grafana"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.grafana_proxy.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/prometheus"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.prometheus_proxy.metadata[0].name
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_v1.grafana_proxy,
    kubernetes_service_v1.prometheus_proxy
  ]
}

resource "kubernetes_ingress_v1" "observability_ingress_alertmanager" {
  metadata {
    name      = "observability-ingress-alertmanager"
    namespace = "default"

    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/alertmanager(/|$)(.*)"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = kubernetes_service_v1.alertmanager_proxy.metadata[0].name
              port {
                number = 9093
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_v1.alertmanager_proxy
  ]
}
