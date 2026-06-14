#!/bin/bash
# 1. Update system and install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 2. Set Variables 
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-frontend"
IMAGE_TAG="latest"

# 3. Authenticate Docker with AWS ECR using the attached IAM Role
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# 4. Pull the Docker Image
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# Changed -p 80:80 to -p 80:3000
docker run -d --name frontend-app --restart always -p 80:3000 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG