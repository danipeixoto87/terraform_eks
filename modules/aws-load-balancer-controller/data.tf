data "aws_caller_identity" "current" {}

data "tls_certificate" "eks_oidc_tls_certificate" {
  url = var.oidc_url
}