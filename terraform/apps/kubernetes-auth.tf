resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = data.terraform_remote_state.infra.outputs.eks_node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      },
      {
        rolearn  = data.terraform_remote_state.infra.outputs.bastion_role_arn
        username = "bastion"
        groups   = ["system:masters"]
      },
      {
        rolearn  = "arn:aws:iam::797671034493:role/eks-observability-github-actions-role"
        username = "github-actions"
        groups   = ["system:masters"]
      }
    ])
  }

  force = true

}
