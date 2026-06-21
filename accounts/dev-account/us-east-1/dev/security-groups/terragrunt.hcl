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

  # 2. Internal Network Rules (Frontend, Backend, Database, and Monitoring)
  ingress_with_self = [
    {
      rule        = "http-80-tcp"
      description = "Allow traffic from External ALB to React servers"
    },
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "Allow Node.js Backend API traffic"
    },
    {
      rule        = "mysql-tcp"          
      description = "Allow RDS Database traffic (Port 3306)"
    },
    # --- NEW OBSERVABILITY PORTS ---
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "Allow Prometheus internal traffic"
    },
    {
      from_port   = 3100
      to_port     = 3100
      protocol    = "tcp"
      description = "Allow Promtail to Loki logs traffic"
    },
    {
      from_port   = 4317
      to_port     = 4318
      protocol    = "tcp"
      description = "Allow OpenTelemetry Collector traces (gRPC/HTTP)"
    }
  ]

  # 3. Allow all outgoing traffic
  egress_rules = ["all-all"]
}