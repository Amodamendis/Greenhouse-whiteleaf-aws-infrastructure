#!/bin/bash
echo "React Server Booting Up..."

# 1. Update system and install Docker & Prometheus Node Exporter
apt-get update -y
apt-get install docker.io python3-pip prometheus-node-exporter -y
pip3 install awscli

# 2. Start Services
systemctl start docker
systemctl enable docker
systemctl start prometheus-node-exporter
systemctl enable prometheus-node-exporter
usermod -aG docker ubuntu

# 3. Install the Grafana Loki Docker Logging Driver
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

# 4. Variables for ECR
ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-frontend"
IMAGE_TAG="latest"

# 5. Authenticate and Pull
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# 6. Run the container
docker run -d --name frontend-app --restart always -p 80:80 \
  --log-driver=loki \
  --log-opt loki-url="http://10.0.11.38:3100/loki/api/v1/push" \
  --log-opt loki-retries=5 \
  --log-opt loki-batch-size=400 \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG