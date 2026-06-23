#!/bin/bash
echo "Backend Application Tier Booting Up..."

# 1. Update system packages and install Docker, AWS CLI, and Node Exporter
apt-get update -y
apt-get install docker.io awscli prometheus-node-exporter -y

# 2. Start Services
systemctl start docker
systemctl enable docker
systemctl start prometheus-node-exporter
systemctl enable prometheus-node-exporter
usermod -aG docker ubuntu

# 3. Define operational environment variables
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-backend"
IMAGE_TAG="latest"

# 4. Authenticate and Pull
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# 5. Run the container
docker run -d --name backend-app --restart always --network host \
  -e DB_HOST="whiteleaf-metadata-db.cg9gqgusejxj.us-east-1.rds.amazonaws.com" \
  -e DB_USER="admin" \
  -e DB_PASSWORD="200317511002" \
  -e DB_NAME="greenhouse_db" \
  -e DB_PORT="3306" \
  -e OTEL_SERVICE_NAME="greenhouse-backend-api" \
  -e OTEL_EXPORTER_OTLP_ENDPOINT="http://10.0.11.38:4318" \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG