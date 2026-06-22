#!/bin/bash
echo "Backend Application Tier Booting Up..."

# Update system packages and install Docker and AWS CLI
apt-get update -y
apt-get install docker.io awscli -y
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Define operational environment variables
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-backend"
IMAGE_TAG="latest"

# Authenticate with AWS Elastic Container Registry (ECR)
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull the latest backend Docker image from ECR
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# Run the container using host networking + OpenTelemetry vars
docker run -d --name backend-app --restart always --network host \
  -e DB_HOST="whiteleaf-metadata-db.cg9gqgusejxj.us-east-1.rds.amazonaws.com" \
  -e DB_USER="admin" \
  -e DB_PASSWORD="200317511002" \
  -e DB_NAME="greenhouse_db" \
  -e DB_PORT="3306" \
  -e OTEL_SERVICE_NAME="greenhouse-backend-api" \
  -e OTEL_EXPORTER_OTLP_ENDPOINT="http://10.0.11.38:4318/v1/traces" \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG