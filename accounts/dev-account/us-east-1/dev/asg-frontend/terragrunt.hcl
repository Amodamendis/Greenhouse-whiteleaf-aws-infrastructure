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

  image_id      = "ami-0c7217cdde317cfec" 
  instance_type = "t3.micro" 
  
  security_groups           = [dependency.security_groups.outputs.security_group_id]
  iam_instance_profile_name = dependency.iam.outputs.iam_instance_profile_name

  vpc_zone_identifier = dependency.vpc.outputs.public_subnets
  target_group_arns   = dependency.alb_external.outputs.target_group_arns
  health_check_type   = "EC2"

  # 1. THE NETWORK FIX: Force AWS to assign a Public IP so it can reach the internet
  associate_public_ip_address = true

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  # 2. THE APPLICATION FIX: Actually pull and run the Docker container
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "React Server Booting Up..."
    
    # Update and install Docker
    apt-get update -y
    apt-get install docker.io -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # Variables for ECR (Replace ACCOUNT_ID if needed)
    ACCOUNT_ID="619891987476"
    REGION="us-east-1"
    ECR_REPO="greenhouse-frontend"
    IMAGE_TAG="latest"

    # Authenticate with AWS ECR, Pull the Image, and Run the Container
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
    docker run -d --name frontend-app --restart always -p 80:80 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
  EOF
  )

  tags = {
    Tier = "Frontend"
  }
}