resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
