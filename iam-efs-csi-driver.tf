
#----------------------------------------------------------------------------------
# comment out this, because the more better to provision the EFS is to use external NFS provisioner
#----------------------------------------------------------------------------------


# data "aws_iam_policy_document" "aws_efs_csi_driver_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "aws_efs_csi_driver" {
#     assume_role_policy = data.aws_iam_policy_document.aws_efs_csi_driver_assume_role_policy.json
#     name = "aws-efs-csi-driver"
  
# }

# resource "aws_iam_policy" "aws_efs_csi_driver_policy" {
#     policy = file("./EFS_CSI_Driver/policy.json")
#     name = "AWSEFScsiDriverPolicy"
  
# }

# resource "aws_iam_role_policy_attachment" "aws_efs_csi_driver_attach" {
#     role = aws_iam_role.aws_efs_csi_driver.name
#     policy_arn = aws_iam_policy.aws_efs_csi_driver_policy.arn
  
# }

# output "aws_efs_csi_role_arn" {
#     value = aws_iam_role.aws_efs_csi_driver.arn
  
# }