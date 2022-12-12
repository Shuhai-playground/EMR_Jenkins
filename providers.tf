provider "aws" {
    region = "us-east-1"
}

terraform {
  required_providers{
    aws={
        source="hashicorp/aws"
        version = "~> 4.39"
    }
    tls = {
        source = "hashicorp/tls"
        version = "~> 4.0"
    }
  }
}



provider "kubernetes" {
    host                   = aws_eks_cluster.demo.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
    exec {
        api_version= "client.authentication.k8s.io/v1beta1"
        args = ["eks","get-token","--cluster-name", aws_eks_cluster.demo.id]
        command = "aws"
      }
    #load_config_file       = false
}