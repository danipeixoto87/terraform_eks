variable "project_name" {
  description = "The project name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(any)
}

variable "oidc_url" {
  description = "ID OIDC for IAM Role"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "vpc_id" {
  description = "EKS VPC ID"
  type        = string
}