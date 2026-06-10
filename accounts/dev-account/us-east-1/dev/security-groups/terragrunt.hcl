include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws//?version=5.1.0"
}

dependency "vpc" {
  config_path = "../vpc"
  
  # We MUST keep this mock output here so the plan doesn't crash!
  mock_outputs = {
    vpc_id = "mock-vpc-id-123"
  }
}

inputs = {
  name        = "greenhouse-security-groups"
  description = "Security groups for the 3-tier greenhouse web application"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # 1. External ALB Security Group (Public Internet Access)
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from public internet"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from public internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # 2. Web Tier Security Group (React Servers)
  # Only allows HTTP traffic originating from the External ALB Security Group
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = "this.security_group_id" 
      description              = "Allow traffic from External ALB"
    }
  ]

  # 3. Data Tier Security Group (RDS MySQL)
  egress_rules = ["all-all"]
}