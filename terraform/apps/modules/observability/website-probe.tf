resource "kubernetes_manifest" "website_probe" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "Probe"

    metadata = {
      name      = "website"
      namespace = "monitoring"
      labels = {
        release = "kube-prometheus-stack"
      }
    }

    spec = {
      interval = "30s"
      module   = "http_2xx"

      prober = {
        url    = "prometheus-blackbox-exporter.monitoring.svc.cluster.local:9115"
        path   = "/probe"
        scheme = "http"
      }

      targets = {
        staticConfig = {
          static = [
            "http://website.default.svc.cluster.local:80/"
          ]
        }
      }
    }
  }
}
