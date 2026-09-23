resource "aws_iam_role" "eks_controller_role" {
  name = "${var.project_name}-lb-controller"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.oidc_url, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(var.oidc_url, "https://", "")}:aud": "sts.amazonaws.com",
          "${replace(var.oidc_url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-lb-controller"
    }
  )
}

#Policy Attachment

resource "aws_iam_role_policy_attachment" "eks_controller_role_attach" {
  role       = aws_iam_role.eks_controller_role.name
  policy_arn = aws_iam_policy.eks_controller_policy.arn
}
