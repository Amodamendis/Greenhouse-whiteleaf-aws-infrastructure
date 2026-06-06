locals {
  # 1. Fallback path for missing YAMLs
  default_yaml_path = find_in_parent_folders("empty.yaml")
  
  # 2. Decode the YAML files in your folder hierarchy
  org         = yamldecode(file(find_in_parent_folders("org.yaml", local.default_yaml_path)))
  account     = yamldecode(file(find_in_parent_folders("account.yaml", local.default_yaml_path)))
  region      = yamldecode(file(find_in_parent_folders("region.yaml", local.default_yaml_path)))
  environment = yamldecode(file(find_in_parent_folders("env.yaml", local.default_yaml_path)))
}

# 3. Generate the AWS Provider
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region.aws_region}"
  
  # Safety feature: Ensures Terragrunt only runs in YOUR specific AWS account
  allowed_account_ids = ["${local.account.aws_account_id}"]
}
EOF
}

# 4. Generate the S3 Backend for State Management
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.org.project}-tfstate-${local.account.aws_account_id}-${local.region.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region.aws_region
    encrypt        = true
    use_lockfile   = true  # <-- This replaces DynamoDB!
  }
}

# 5. Merge all YAML variables into Terraform inputs
inputs = merge(
  local.org,
  local.account,
  local.region,
  local.environment
)