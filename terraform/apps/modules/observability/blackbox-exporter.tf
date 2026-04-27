resource "helm_release" "prometheus_blackbox_exporter" {
  name             = "prometheus-blackbox-exporter"
  namespace        = "monitoring"
  create_namespace = false

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  values = [
    yamlencode({
      releaseLabel = true
    })
  ]
}
