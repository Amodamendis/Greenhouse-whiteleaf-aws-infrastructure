include "root" {
  path = find_in_parent_folders()
}

# Utilizing the standard AWS EC2 module
terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws//?version=6.4.0"
}

# Pulling in state from your existing infrastructure layers
dependency "vpc" {
  config_path = "../vpc"
}

dependency "sg" {
  config_path = "../security-groups"
}

dependency "iam" {
  config_path = "../iam"
}

inputs = {
  name          = "greenhouse-monitoring-server"
  
  # Ubuntu 24.04 LTS AMI (us-east-1)
  ami           = "ami-04b70fa74e45c3917" 
  instance_type = "t3.medium"
  
  # Deploying into the private subnet alongside your App Tier
  subnet_id                   = dependency.vpc.outputs.private_subnets[0]
  associate_public_ip_address = false

  # Attaching the IAM role you previously built to enable the SSM tunnel
  iam_instance_profile = dependency.iam.outputs.iam_instance_profile_name
  
  # Make sure to update 'monitoring_sg_id' to match the exact output name from your security-groups module
  vpc_security_group_ids = [dependency.sg.outputs.security_group_id]

  # Root volume for the OS and Docker Engine
  root_block_device = {
    volume_size = 20
    volume_type = "gp3"
  }

  # Dedicated EBS volume [Used to ensure Prometheus time-series data and Loki logs persist independently]
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_size = 20
      volume_type = "gp3"
    }
  ]

  # User Data script to automatically install Docker and Docker Compose on boot
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y ca-certificates curl gnupg
              sudo install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              sudo chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Environment = "dev"
    Role        = "monitoring-platform"
  }
}