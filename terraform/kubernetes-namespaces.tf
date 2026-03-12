resource "kubernetes_namespace_v1" "observability" {
  metadata {
    name = "observability"
    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
