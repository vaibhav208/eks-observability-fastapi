output "monitoring_namespace" {
  value = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "prometheus_release_name" {
  value = helm_release.kube_prometheus_stack.name
}
