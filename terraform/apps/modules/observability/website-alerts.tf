resource "kubernetes_manifest" "website_alerts" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "website-alerts"
      namespace = "monitoring"
      labels = {
        release = "kube-prometheus-stack"
      }
    }

    spec = {
      groups = [
        {
          name = "website.rules"
          rules = [
            {
              alert = "WebsiteDown"
              expr  = "probe_success{instance=\"http://website.default.svc.cluster.local:80/\"} == 0"
              for   = "30s"

              labels = {
                severity = "critical"
              }

              annotations = {
                summary     = "Website is down"
                description = "Website is not reachable via HTTP probe"
              }
            }
          ]
        }
      ]
    }
  }
}
