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
  }
  backend "s3" {
    bucket = "shwatech-terraform-k8s-platform-111"
    key    = "aws/00_foundations"
    region = "us-east-1"
  }
}


## Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}


## Configure the Kubernetes provider to interact with the EKS cluster
## using the cluster details from the EKS module
provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
  }
}