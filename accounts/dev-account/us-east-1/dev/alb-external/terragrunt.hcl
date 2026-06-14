include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/alb/aws//?version=8.7.0"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id         = "mock-vpc-id"
    public_subnets = ["mock-pub-subnet-1", "mock-pub-subnet-2"]
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_id = "mock-sg-id"
  }
}

inputs = {
  name = "greenhouse-external-alb"

  # CRITICAL DIFFERENCE: internal = false means this ALB gets a public IP address!
  internal           = false
  load_balancer_type = "application"

  vpc_id          = dependency.vpc.outputs.vpc_id
  
  # Placed strictly in the PUBLIC subnets
  subnets         = dependency.vpc.outputs.public_subnets
  
  # Uses the public-facing security group we defined in Phase 2
  security_groups = [dependency.security_groups.outputs.security_group_id]

  target_groups = [
    {
      name_prefix      = "web-tg"
      backend_protocol = "HTTP"
      backend_port     = 80 # Assuming React is served via Nginx on port 80
      target_type      = "instance"
      
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/" # Pings the root of your React app
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Tier = "Frontend"
  }
}