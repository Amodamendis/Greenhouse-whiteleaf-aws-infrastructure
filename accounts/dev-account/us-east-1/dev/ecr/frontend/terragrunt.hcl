include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/ecr/aws//?version=2.2.1"
}

inputs = {
  repository_name = "greenhouse-frontend"

  # Allows you to overwrite the 'latest' tag when testing new code
  repository_image_tag_mutability = "MUTABLE"

  # Security feature: AWS will scan your React image for vulnerabilities automatically
  repository_image_scan_on_push = true

  # Cost-saving feature: AWS will automatically delete older images so you don't pay for stale storage
  create_lifecycle_policy = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only the last 5 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}