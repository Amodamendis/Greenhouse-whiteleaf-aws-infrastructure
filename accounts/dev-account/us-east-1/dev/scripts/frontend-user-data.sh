#!/bin/bash
echo "React Server Booting Up..."

# Update system and install Docker
apt-get update -y
apt-get install docker.io python3-pip -y
pip3 install awscli
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install the Grafana Loki Docker Logging Driver
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

# Variables for ECR
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-frontend"
IMAGE_TAG="latest"

# Authenticate Docker with AWS ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull the Docker Image
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# Run the container and route all Nginx logs to the Monitoring Server (10.0.11.38)
docker run -d --name frontend-app --restart always -p 80:80 \
  --log-driver=loki \
  --log-opt loki-url="http://10.0.11.38:3100/loki/api/v1/push" \
  --log-opt loki-retries=5 \
  --log-opt loki-batch-size=400 \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG