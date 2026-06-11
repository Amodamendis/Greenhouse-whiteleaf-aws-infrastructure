include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/ecr/aws//?version=2.2.1"
}

inputs = {
  # This MUST match the ECR_REPOSITORY variable in your GitHub Actions cicd.yml exactly
  repository_name = "greenhouse-frontend"

  # Allows your CI/CD pipeline to overwrite the 'latest' tag on every new push
  repository_image_tag_mutability = "MUTABLE"

  # SRE Guardrail: Automatically purge old images to optimize cloud storage costs
  create_lifecycle_policy = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only the newest 10 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Tier = "Frontend"
  }
}