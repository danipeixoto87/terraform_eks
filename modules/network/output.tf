output "subnet_public_1a" {
  value = aws_subnet.eks-public-1a.id
}

output "subnet_public_1b" {
  value = aws_subnet.eks-public-1b.id
}

output "subnet_private_1a" {
  value = aws_subnet.eks-private-1a.id
}

output "subnet_private_1b" {
  value = aws_subnet.eks-private-1b.id
}