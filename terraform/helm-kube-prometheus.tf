resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "81.2.2"
  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]


  values = [yamlencode({

    grafana = {
      adminUser     = "admin"
      adminPassword = "prom-operator"

      sidecar = {
        dashboards = {
          enabled           = true
          label             = "grafana_dashboard"
          folder            = "/var/lib/grafana/dashboards/default"
          defaultFolderName = "default"
          searchNamespace   = "ALL"
        }
      }

      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [{
            name            = "default"
            orgId           = 1
            folder          = ""
            type            = "file"
            disableDeletion = false
            editable        = true
            options = {
              path = "/var/lib/grafana/dashboards/default"
            }
          }]
        }
      }
    }

    alertmanager = {
      config = {
        global = {}

        route = {
          receiver = "null-receiver"
          group_by = ["alertname", "severity"]
          group_wait = "30s"
          group_interval = "5m"
          repeat_interval = "4h"
        }

        receivers = [
          { name = "null-receiver" }
        ]
      }
    }

  })]
}
