include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/autoscaling/aws//?version=9.2.1"
}

# 1. We need the private subnets to place the servers securely
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnets = ["mock-subnet-1", "mock-subnet-2"]
  }
}

# 2. We need the firewalls
dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_id = "mock-sg-id"
  }
}

# 3. We need the ALB's Target Group so the servers know where to register themselves
dependency "alb_internal" {
  config_path = "../alb-internal"
  mock_outputs = {
    target_group_arns = ["mock-tg-arn"]
  }
}

# 4. We need the IAM Role so the servers have permission to download your Node.js Docker image
dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    iam_instance_profile_name = "mock-instance-profile"
  }
}

inputs = {
  name = "greenhouse-backend-asg"

  # --- LAUNCH TEMPLATE ---
  # This acts as the "blueprint" for every new server the ASG spins up
  image_id      = "ami-0c7217cdde317cfec" # Standard Ubuntu Linux AMI placeholder
  instance_type = "t3.micro" 
  
  security_groups           = [dependency.security_groups.outputs.security_group_id]
  iam_instance_profile_name = dependency.iam.outputs.iam_instance_profile_name

  # --- AUTO SCALING RULES ---
  vpc_zone_identifier = dependency.vpc.outputs.private_subnets
  target_group_arns   = dependency.alb_internal.outputs.target_group_arns
  health_check_type   = "EC2" # Checks if the physical server is online

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  # --- BOOTSTRAP SCRIPT (User Data) ---
  # This bash script runs automatically exactly ONE time when a new server boots up.
  # For your Node.js app, this is where you will eventually tell it to install Docker, 
  # pull your image from ECR, and run it!
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Server Booting Up..."
    apt-get update -y
    apt-get install docker.io -y
    systemctl start docker
    # Future step: aws ecr get-login-password | docker login ...
    # Future step: docker run -p 8080:8080 greenhouse-backend:latest
  EOF
  )

  tags = {
    Tier = "Backend"
  }
}