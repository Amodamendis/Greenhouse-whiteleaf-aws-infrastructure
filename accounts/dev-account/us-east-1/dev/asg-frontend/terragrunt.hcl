include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/autoscaling/aws//?version=9.2.1"
}

# 1. FIX: Grab the private subnets instead of public
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnets = ["mock-subnet-1", "mock-subnet-2"]
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

  image_id      = "ami-0c7217cdde317cfec" 
  instance_type = "t3.micro" 
  
  security_groups           = [dependency.security_groups.outputs.security_group_id]
  iam_instance_profile_name = dependency.iam.outputs.iam_instance_profile_name

  # 2. FIX: Place the servers in the Private Subnet so they use the NAT Gateway
  vpc_zone_identifier = dependency.vpc.outputs.private_subnets

  health_check_type   = "ELB"

  target_group_arns = dependency.alb_external.outputs.target_group_arns
   
  
  create_traffic_source_attachment = true 

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  user_data = base64encode(file("../scripts/frontend-user-data.sh"))

  tags = {
    Tier = "Frontend"
  }
}