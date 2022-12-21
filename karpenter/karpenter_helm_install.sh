#! /bin/bash
# to install karpenter with helm

echo "Start to install karpenter with helm..."

KARPENTER_IAM_ROLE_ARN=$(terraform output karpenter_controller_arn)
CLUSTER_NAME=$(terraform output eks_cluster_id)
CLUSTER_ENDPOINT=$(terraform output eks_endpoint)
INSTANCE_PROFILE=$(terraform output instanceprofile_karpenter)



# helm upgrade --install --namespace karpenter --create-namespace \
#   karpenter oci://public.ecr.aws/karpenter/karpenter \
#   --version v0.20.0 \
# #   --set serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$KARPENTER_IAM_ROLE_ARN \
#   --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$KARPENTER_IAM_ROLE_ARN \
#   --set settings.aws.clusterName=$CLUSTER_NAME \
#   --set settings.aws.clusterEndpoint=$CLUSTER_ENDPOINT \
#   --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-$INSTANCE_PROFILE \
#   --set settings.aws.interruptionQueueName=$CLUSTER_NAME \
#   --wait

helm upgrade --install karpenter-controller oci://public.ecr.aws/karpenter/karpenter --version v0.20.0 --namespace karpenter --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$KARPENTER_IAM_ROLE_ARN \
  --set settings.aws.clusterName=$CLUSTER_NAME \
  --set settings.aws.clusterEndpoint=$CLUSTER_ENDPOINT \
  --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-$INSTANCE_PROFILE \
  --set settings.aws.interruptionQueueName=$CLUSTER_NAME \
  --wait


