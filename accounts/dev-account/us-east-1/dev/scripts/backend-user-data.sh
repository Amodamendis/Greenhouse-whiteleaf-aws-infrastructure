#!/bin/bash
echo "Node.js Backend Server Booting Up..."

apt-get update -y
apt-get install docker.io python3-pip -y
pip3 install awscli
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

ACCOUNT_ID="619891987476"
REGION="us-east-1"
ECR_REPO="greenhouse-backend"
IMAGE_TAG="latest"

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

docker run -d --name backend-app --restart always -p 4000:4000 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG