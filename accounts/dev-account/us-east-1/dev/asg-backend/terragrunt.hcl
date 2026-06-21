include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/autoscaling/aws//?version=9.2.1"
}

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

dependency "alb_internal" {
  config_path = "../alb-internal"
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
  name = "greenhouse-backend-asg"

  image_id      = "ami-0c7217cdde317cfec"
  instance_type = "t3.micro" 
  
  security_groups           = [dependency.security_groups.outputs.security_group_id]
  iam_instance_profile_name = dependency.iam.outputs.iam_instance_profile_name

  vpc_zone_identifier = dependency.vpc.outputs.private_subnets

  # --- THE FIX: NEW V9 SYNTAX TO ATTACH THE ASG TO THE ALB ---
  traffic_source_attachments = {
    internal_alb = {
      traffic_source_identifier = dependency.alb_internal.outputs.target_group_arns[0]
      traffic_source_type       = "elbv2"
    }
  }

  health_check_type   = "ELB" 

  min_size         = 1
  max_size         = 3
  desired_capacity = 1


  # --- THE FIX: ALLOW DOCKER CONTAINERS TO READ AWS IAM CREDENTIALS ---
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2  # Increased from 1 to 2 to cross the Docker bridge!
  }
  
  # Connect directly to your external backend script
  user_data = base64encode(file("../scripts/backend-user-data.sh"))

  tags = {
    Tier = "Backend"
  }
}