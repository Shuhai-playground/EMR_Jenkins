module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "18.31.0"

  cluster_name = aws_eks_cluster.demo.id

  irsa_oidc_provider_arn          = aws_iam_openid_connect_provider.eks.arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  # Since Karpenter is running on an EKS Managed Node group,
  # we can re-use the role that was created for the node group
  create_iam_role = false
  iam_role_arn    = aws_iam_role.karpenter_controller.arn
}