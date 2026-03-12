resource "helm_release" "fastapi" {
  name      = "fastapi"
  namespace = kubernetes_namespace_v1.observability.metadata[0].name
  chart     = "../helm/fastapi"

  depends_on = [
    kubernetes_namespace_v1.observability
  ]
}
