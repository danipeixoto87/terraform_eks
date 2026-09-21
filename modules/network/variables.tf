variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(any)
}