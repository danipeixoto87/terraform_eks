output "subnet_public_1a" {
  value = module.eks_network.subnet_public_1a
}

output "subnet_public_1b" {
  value = module.eks_network.subnet_public_1b
}

output "subnet_private_1a" {
  value = module.eks_network.subnet_private_1a
}

output "subnet_private_1b" {
  value = module.eks_network.subnet_private_1b
}

output "eks_vpc_config" {
  value = module.eks_cluster.eks_vpc_config
}