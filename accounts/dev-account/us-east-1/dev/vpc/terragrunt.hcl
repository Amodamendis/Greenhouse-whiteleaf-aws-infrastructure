# This tells Terragrunt to climb up the directories, find the root terragrunt.hcl, 
# and automatically inherit the AWS provider and S3 backend state configurations!
include "root" {
  path = find_in_parent_folders()
}

# This tells Terragrunt where to download the verified AWS VPC module from the public registry
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws//?version=5.0.0"
}

# These are the specific inputs that map directly to your 2 Availability Zone architecture layout
inputs = {
  name = "whiteleaf-vpc"
  cidr = "10.0.0.0/16"

  # Setting up high availability across two AZs (AZ-1a and AZ-1b)
  azs             = ["us-east-1a", "us-east-1b"]
  
  # Your network splits: Public (Web), Private App (Node.js), Private Data (MySQL RDS)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]  # Web Tier
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"] # App Tier
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"] # Database Tier

  # NAT Gateway setup so private resources can safely download updates from the web
  enable_nat_gateway = true
  single_nat_gateway = true # Keeps costs low for your development environment
  
  # Crucial database subnet configurations
  create_database_subnet_group = true
  
  tags = {
    Environment = "dev"
    Project     = "WhiteleafAgri"
  }
}