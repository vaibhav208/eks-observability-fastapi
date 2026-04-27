module "observability" {
  source      = "./modules/observability"
  environment = "dev"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}



module "ingress_nginx" {
  source = "./modules/ingress-nginx"
}

module "observability_routing" {
  source = "./modules/observability-routing"

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    module.observability
  ]
}
