

# data "aws_iam_instance_profile" "karpenter" {
#   name = "karpenter"
  
# }

# output "profile" {
#   value=data.aws_iam_instance_profile.karpenter.arn
# }

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "v0.20.0"

  set {
    name  = "settings.aws.clusterName"
    value = aws_eks_cluster.demo.id
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = aws_eks_cluster.demo.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = "arn:aws:iam::182232283818:instance-profile/eks-a4c29c88-e18e-0479-2bf1-8c4a737b9aab"
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = aws_eks_cluster.demo.id
  }
}