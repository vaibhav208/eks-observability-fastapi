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

            {
              alert = "FastAPIHighErrorRate"
              expr  = "sum(rate(http_requests_total{status=~\"5..\"}[1m])) > 1"
              for   = "1m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High error rate in FastAPI"
                description = "FastAPI is returning too many 5xx errors"
              }
            },

            {
              alert = "FastAPIHighLatency"
              expr  = "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 1"
              for   = "1m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High latency in FastAPI"
                description = "P95 latency is greater than 1 second"
              }
            },

            {
              alert = "FastAPIDown"
              expr = "kube_deployment_status_replicas_available{namespace=\"default\", deployment=\"fastapi-app\"} == 0"
              for   = "30s"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "FastAPI is down"
                description = "FastAPI is not reachable by Prometheus"
              }
            }

          ]
        }
      ]
    }
  }
}
