output "eks_cluster_id" {
  value=aws_eks_cluster.demo.id
}

output "karpenter_controller_arn" {
  value = aws_iam_role.karpenter_controller.arn
}

output "eks_endpoint" {
    value = aws_eks_cluster.demo.endpoint
  
}

output "instanceprofile_karpenter" {
    value = aws_iam_instance_profile.karpenter.name
  
}