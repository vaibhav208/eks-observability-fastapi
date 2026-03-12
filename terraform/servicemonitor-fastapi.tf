resource "kubernetes_manifest" "fastapi_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "fastapi"
      namespace = "monitoring"
      labels = {
        release = "kube-prometheus-stack"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          app = "fastapi"
        }
      }

      namespaceSelector = {
        matchNames = ["observability"]
      }

      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "15s"
        }
      ]
    }
  }

  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}
