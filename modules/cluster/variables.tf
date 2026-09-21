variable "project_name" {
  description = "The project name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(any)
}

variable "public_subnet_1a" {
  description = "Subnet to creat EKS Cluster AZ 1a"
  type        = string
}

variable "public_subnet_1b" {
  description = "Subnet to creat EKS Cluster AZ 1b"
  type        = string
}