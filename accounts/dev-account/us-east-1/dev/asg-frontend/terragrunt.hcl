include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/autoscaling/aws//?version=9.2.1"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    public_subnets = ["mock-pub-subnet-1", "mock-pub-subnet-2"]
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_id = "mock-sg-id"
  }
}

dependency "alb_external" {
  config_path = "../alb-external"
  mock_outputs = {
    target_group_arns = ["mock-tg-arn"]
  }
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    iam_instance_profile_name = "mock-instance-profile"
  }
}

inputs = {
  name = "greenhouse-frontend-asg"

  image_id      = "ami-0c7217cdde317cfec" # Ubuntu AMI
  instance_type = "t3.micro" 
  
  security_groups           = [dependency.security_groups.outputs.security_group_id]
  iam_instance_profile_name = dependency.iam.outputs.iam_instance_profile_name

  # Place these servers in the PUBLIC subnets
  vpc_zone_identifier = dependency.vpc.outputs.public_subnets
  target_group_arns   = dependency.alb_external.outputs.target_group_arns
  health_check_type   = "EC2"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "React Server Booting Up..."
    apt-get update -y
    apt-get install docker.io -y
    systemctl start docker
    # Future step: aws ecr get-login-password | docker login ...
    # Future step: docker run -p 80:80 greenhouse-frontend:latest
  EOF
  )

  tags = {
    Tier = "Frontend"
  }
}