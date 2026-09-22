variable "project_name" {
  description = "The project name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(any)
}

variable "cluster_name" {
  description = "EKS Cluster Name to creat MNG"
  type        = string
}

variable "subnet_private_1a" {
  description = "Subnet from AZ 1a"
  type        = string
}

variable "subnet_private_1b" {
  description = "Subnet from AZ 1b"
  type        = string
}
