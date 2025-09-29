

## This file contains Kubernetes manifests for cert-manager and external-secrets
data "kubernetes_service_v1" "ingress_service" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}


## Create DNS record for Ingress Controller in Route53
variable "domain" {
  description = "AWS Route53 hosted zone domain name"
  type        = string
  default = "shwatech.dev"
}


## Email for Let's Encrypt notifications
variable "email" {
  description = "Letsencrypt email"
  type        = string
}


## Fetch the Route53 hosted zone based on the provided domain
data "aws_route53_zone" "default" {
  name = var.domain
}


## Create a DNS record for the Ingress controller
resource "aws_route53_record" "ingress_record" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = "app.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [
    data.kubernetes_service_v1.ingress_service.status.0.load_balancer.0.ingress.0.hostname
  ]
}


## Create a ClusterIssuer for cert-manager using Let's Encrypt
resource "kubernetes_manifest" "cert_issuer" {
  manifest = yamldecode(<<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${var.email}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
  YAML
  )

  depends_on = [
    aws_route53_record.ingress_record
  ]
}


## Create a Namespace for External Secrets
data "aws_caller_identity" "current" {}
resource "kubernetes_service_account_v1" "secret_store" {
  metadata {
    namespace = "external-secrets"
    name      = "secret-store"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/secret-store"
    }
  }
}


## Create a ClusterSecretStore for External Secrets
resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = yamldecode(<<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-store
spec:
  provider:
    aws:
      service: ParameterStore
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            namespace: external-secrets
            name: secret-store
  YAML
  )

  depends_on = [
    kubernetes_service_account_v1.secret_store
  ]
}
