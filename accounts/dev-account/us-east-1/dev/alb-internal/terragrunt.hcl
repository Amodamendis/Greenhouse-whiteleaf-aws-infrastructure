include "root" {
  path = find_in_parent_folders()
}

terraform {
  # Official AWS ALB module
  source = "tfr:///terraform-aws-modules/alb/aws//?version=8.7.0"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id          = "mock-vpc-id"
    private_subnets = ["mock-subnet-1", "mock-subnet-2"]
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  
  mock_outputs = {
    security_group_id = "mock-sg-id"
  }
}

inputs = {
  name = "greenhouse-internal-alb"

  # VERY IMPORTANT: This makes the load balancer private so the internet cannot touch it
  internal           = true
  load_balancer_type = "application"

  # We place this strictly in the private subnets
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnets         = dependency.vpc.outputs.private_subnets
  security_groups = [dependency.security_groups.outputs.security_group_id]

  # Target Group: This is the "waiting room" where the ALB sends traffic
  target_groups = [
    {
      name_prefix      = "app-tg"
      backend_protocol = "HTTP"
      
      # FIX: Align to the Node.js server.js port
      backend_port     = 4000 
      target_type      = "instance"
      
      health_check = {
        enabled             = true
        interval            = 30
        # FIX: Align to the exact string in server.js
        path                = "/api/health" 
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }
    }
  ]

  # Listeners: The ALB listens on port 80 and forwards to the Target Group
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Tier = "Backend"
  }
}