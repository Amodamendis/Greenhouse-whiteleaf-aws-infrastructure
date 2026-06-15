#!/bin/bash
echo "React Server Booting Up..."

# Update system and install Docker
apt-get update -y
apt-get install docker.io python3-pip -y
pip3 install awscli
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Variables for ECR
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-frontend"
IMAGE_TAG="latest"

# Authenticate Docker with AWS ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull and Run the Docker Image
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
docker run -d --name frontend-app --restart always -p 80:80 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG