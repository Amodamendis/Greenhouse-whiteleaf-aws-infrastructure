inputs = {
  name        = "greenhouse-security-groups"
  description = "Security groups for the 3-tier greenhouse web application"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # 1. Allow Public Internet to hit the External ALB
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

  # 2. Allow Internal Tiers to Talk to Each Other
  # This opens the doors for your React app, Node app, and Database!
  ingress_with_self = [
    {
      rule        = "http-80-tcp"
      description = "Allow Frontend and Internal ALB traffic"
    },
    {
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      description = "Allow Backend API traffic"
    },
    {
      rule        = "mysql-tcp"
      description = "Allow Database traffic (Port 3306)"
    }
  ]

  egress_rules = ["all-all"]
}