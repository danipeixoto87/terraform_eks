resource "aws_eks_node_group" "eks_mng" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-nodegroup"
  node_role_arn   = aws_iam_role.eks_mng_role.arn
  subnet_ids = [
    var.subnet_private_1a,
    var.subnet_private_1a
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nodegroup"
    }
  )

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.mng_role_attach_worker,
    aws_iam_role_policy_attachment.mng_role_attach_cr,
    aws_iam_role_policy_attachment.mng_role_attach_cni
  ]
}

