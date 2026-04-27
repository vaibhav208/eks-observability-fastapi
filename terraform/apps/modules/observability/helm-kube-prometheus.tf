resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "81.2.2"

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  values = [
    yamlencode({

      prometheusBlackboxExporter = {
        enabled = true
      }

      grafana = {
        adminUser     = "admin"
        adminPassword = "prom-operator"

        serviceMonitor = {
            enabled = false
          }

        "grafana.ini" = {
          server = {
            root_url            = "http://a6b30234174294ddc819d213eac8e371-1913973493.us-east-1.elb.amazonaws.com/grafana"
            serve_from_sub_path = true
          }
        }

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

      prometheus = {
        prometheusSpec = {

          probeNamespaceSelector = {}

          probeSelector = {
            matchLabels = {
              release = "kube-prometheus-stack"
            }
          }

          externalUrl = "http://a6b30234174294ddc819d213eac8e371-1913973493.us-east-1.elb.amazonaws.com/prometheus"
          routePrefix = "/prometheus"

          serviceMonitorNamespaceSelector = {}
          alertingEndpoints = [
            {
              name      = "kube-prometheus-stack-alertmanager"
              namespace = "monitoring"
              port      = "http-web"
            }
          ]
        }
      }

      alertmanager = {
        enabled = true

        alertmanagerSpec = {
          replicas = 1
        }

        config = {
          global = {
            smtp_smarthost = "smtp.gmail.com:587"
            smtp_from      = "abhaykumarsaini9982@gmail.com"
            smtp_auth_username = "abhaykumarsaini9982@gmail.com"
            smtp_auth_password = "wkgq nlix rvqt bfit"
            smtp_require_tls   = true
          }

          route = {
            receiver = "email-notifications"
            group_by = ["alertname"]
            group_wait = "10s"
            group_interval = "1m"
            repeat_interval = "1h"
          }

          receivers = [
            {
              name = "null"
            },
            {
              name = "email-notifications"
              email_configs = [
                {
                  to            = "abhaykumarsaini9982@gmail.com"
                  send_resolved = true
                }
              ]
            }
          ]
        }
      }

    })
  ]
}
