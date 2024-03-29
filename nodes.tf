resource "aws_iam_role" "nodes" {
  name="eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}


resource "aws_eks_node_group" "private_nodes" {
    cluster_name = aws_eks_cluster.demo.name
    node_group_name = "private-nodes"
    node_role_arn = aws_iam_role.nodes.arn

    subnet_ids = [
        aws_subnet.private_us_east_1a.id,
        aws_subnet.private_us_east_1b.id
    ]

    capacity_type = "ON_DEMAND"
    instance_types = ["t3.medium"]

    scaling_config {
      desired_size= 2
      max_size= 3
      min_size= 0
    }

    update_config {
      max_unavailable= 1
    }

    labels = {
      "role" = "general"
    }

    depends_on = [
      aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
    ]

    # add remote connection
    remote_access {
      ec2_ssh_key= aws_key_pair.bastion_host.key_name
      source_security_group_ids = [aws_security_group.node_sg.id, aws_security_group.jenkins.id]
    }

    # so here when karpenter scale up and down will be ignored by this default setting
    lifecycle {
      ignore_changes=[scaling_config[0].desired_size]
    }

    # instance_profile = aws_iam_instance_profile.karpenter.id

    tags = {
      "karpenter.sh/discovery" = aws_eks_cluster.demo.id
    }
}


# for adding a tag to security group of nodes for karpenter

# resource "aws_ec2_tag" "example" {
#   resource_id   = "${aws_eks_node_group.private_nodes.security_group_id}"
#   key           = "TagKey"
#   value         = "TagValue"
# }