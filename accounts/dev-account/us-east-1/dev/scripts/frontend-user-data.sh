#!/bin/bash
echo "React Server Booting Up..."

# 1. Update system and install Docker using UBUNTU commands
apt-get update -y
apt-get install docker.io -y
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# 2. Set Variables 
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-frontend"
IMAGE_TAG="latest"

# 3. Authenticate Docker with AWS ECR using the attached IAM Role
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# 4. Pull the Docker Image
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# 5. Run the Container mapping host port 80 to container port 80
docker run -d --name frontend-app --restart always -p 80:80 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG