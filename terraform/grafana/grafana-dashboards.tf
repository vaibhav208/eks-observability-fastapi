resource "kubernetes_config_map_v1" "grafana_fastapi_dashboard" {
  metadata {
    name      = "grafana-fastapi-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "fastapi-golden-signals.json" = file("${path.module}/grafana/dashboards/fastapi-golden-signals.json")
  }
}
