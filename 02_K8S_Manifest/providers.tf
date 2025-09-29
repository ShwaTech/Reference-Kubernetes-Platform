## First You have to create s3 manually as a backend for terraform state management
## You can use AWS Console or AWS CLI to create the S3 bucket
## Example AWS CLI command:
## $ aws s3api create-bucket --bucket shwatech-terraform-k8s-platform-111 --region us-east-1

## You have to start minikube first before running terraform apply
## $ minikube start


## Define the required providers and backend for Terraform state management
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
  backend "s3" {
    bucket = "shwatech-terraform-k8s-platform-111"
    key    = "aws/01_k8s_manifest"
    region = "us-east-1"
  }
}


## Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}


## Fetch the EKS cluster
data "aws_eks_cluster" "cluster" {
  name = "cluster-prod"
}


## Fetch the authentication token for the EKS cluster
data "aws_eks_cluster_auth" "cluster" {
  name = "cluster-prod"
}


## Configure the Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}


## Configure the Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}