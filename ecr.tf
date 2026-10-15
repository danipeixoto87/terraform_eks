resource "aws_ecr_repository" "devops_api" {
  name                 = "devops-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.tags, {
    Name = "devops-api"
  })
}

resource "aws_ecr_lifecycle_policy" "devops_api" {
  repository = aws_ecr_repository.devops_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "ecr_repository_url" {
  description = "URL do repositório ECR da API"
  value       = aws_ecr_repository.devops_api.repository_url
}
