resource "kubernetes_manifest" "fastapi_alerts" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "fastapi-alerts"
      namespace = "monitoring"
      labels = {
        release = "kube-prometheus-stack"
      }
    }

    spec = {
      groups = [
        {
          name = "fastapi.rules"
          rules = [

            # 🔴 High 5xx error rate
            {
              alert = "FastAPIHighErrorRate"
              expr  = <<-EOT
                sum(rate(http_requests_total{status=~"5.."}[2m])) > 0
              EOT
              for = "1m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "FastAPI is returning 5xx errors"
                description = "FastAPI has elevated 5xx responses for over 1 minute"
              }
            },

            # 🟠 High latency P95
            {
              alert = "FastAPIHighLatency"
              expr  = <<-EOT
                histogram_quantile(
                  0.95,
                  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
                ) > 1
              EOT
              for = "2m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "FastAPI latency is high (P95)"
                description = "95th percentile latency > 1s for 2 minutes"
              }
            },

            # 🔴 FastAPI pod down
            {
              alert = "FastAPIPodDown"
              expr  = <<-EOT
                absent(up{job="fastapi"})
              EOT
              for = "30s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "FastAPI is down"
                description = "No FastAPI pods are reachable"

              }
            }
          ]
        }
      ]
    }
  }
}
