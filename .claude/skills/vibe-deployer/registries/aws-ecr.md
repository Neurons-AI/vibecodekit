# AWS Elastic Container Registry (ECR)

> Registry của AWS, tích hợp tốt với các AWS services như ECS, EKS, Lambda.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com` |
| **Free tier** | 500MB storage/month (12 months) |
| **Image format** | `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPO:TAG` |
| **Best for** | AWS deployments, enterprise, high security requirements |

---

## Prerequisites

1. AWS Account
2. AWS CLI installed
3. IAM user/role với permissions

### Install AWS CLI

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download từ https://aws.amazon.com/cli/
```

### Configure AWS CLI

```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: ap-southeast-1 (hoặc region của bạn)
# Default output format: json
```

---

## Setup

### 1. Tạo ECR Repository

```bash
# Tạo repository
aws ecr create-repository \
    --repository-name myapp \
    --image-scanning-configuration scanOnPush=true \
    --region ap-southeast-1

# Output sẽ có repositoryUri
```

### 2. Login vào ECR

```bash
# Get login password và pipe to docker login
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com

# Hoặc lưu vào variable
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com
```

> **Note:** ECR login token hết hạn sau 12 giờ

---

## Usage

### Build & Tag

```bash
# Set variables
AWS_ACCOUNT_ID=123456789012
AWS_REGION=ap-southeast-1
REPO_NAME=myapp

# Build
docker build -t myapp:latest .

# Tag cho ECR
docker tag myapp:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
docker tag myapp:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:v1.0.0
```

### Push

```bash
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:v1.0.0
```

### Pull

```bash
docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
```

---

## IAM Permissions

### Minimum permissions để push/pull

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:REGION:ACCOUNT_ID:repository/REPO_NAME"
    }
  ]
}
```

### AWS Managed Policies

- `AmazonEC2ContainerRegistryReadOnly` - Pull only
- `AmazonEC2ContainerRegistryPowerUser` - Push/Pull
- `AmazonEC2ContainerRegistryFullAccess` - Full access

---

## GitHub Actions Integration

```yaml
name: Build and Push to ECR

on:
  push:
    branches: [main]

env:
  AWS_REGION: ap-southeast-1
  ECR_REPOSITORY: myapp

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

---

## Lifecycle Policies

### Xóa untagged images sau 1 ngày

```bash
aws ecr put-lifecycle-policy \
  --repository-name myapp \
  --lifecycle-policy-text '{
    "rules": [
      {
        "rulePriority": 1,
        "description": "Expire untagged images older than 1 day",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }'
```

### Giữ 10 images mới nhất

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

---

## Image Scanning

### Enable scanning

```bash
# Scan on push
aws ecr put-image-scanning-configuration \
  --repository-name myapp \
  --image-scanning-configuration scanOnPush=true

# Manual scan
aws ecr start-image-scan \
  --repository-name myapp \
  --image-id imageTag=latest
```

### Get scan results

```bash
aws ecr describe-image-scan-findings \
  --repository-name myapp \
  --image-id imageTag=latest
```

---

## Cross-Region Replication

```bash
# Enable replication
aws ecr put-replication-configuration \
  --replication-configuration '{
    "rules": [
      {
        "destinations": [
          {
            "region": "us-west-2",
            "registryId": "ACCOUNT_ID"
          }
        ]
      }
    ]
  }'
```

---

## ECR Public

> Dùng cho public images (như Docker Hub)

```bash
# Login to ECR Public
aws ecr-public get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin public.ecr.aws

# Create public repo
aws ecr-public create-repository --repository-name myapp

# Push
docker tag myapp:latest public.ecr.aws/YOUR_ALIAS/myapp:latest
docker push public.ecr.aws/YOUR_ALIAS/myapp:latest
```

---

## Pricing

| Item | Price |
|------|-------|
| **Storage** | $0.10/GB/month |
| **Data Transfer (out)** | $0.09/GB (varies by region) |
| **Free Tier** | 500MB storage/month for 12 months |

---

## Troubleshooting

### "no basic auth credentials"

```bash
# Login lại (token hết hạn sau 12h)
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com
```

### "denied: User: arn:aws:iam::... is not authorized"

```bash
# Kiểm tra IAM permissions
aws sts get-caller-identity
# Đảm bảo user/role có quyền ecr:*
```

### "repository does not exist"

```bash
# Tạo repository trước
aws ecr create-repository --repository-name myapp
```

---

## Quick Commands

```bash
# === SETUP ===
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=ap-southeast-1
export REPO_NAME=myapp

# === CREATE REPO ===
aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION

# === LOGIN ===
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# === BUILD & PUSH ===
docker build -t $REPO_NAME:latest .
docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest

# === LIST IMAGES ===
aws ecr describe-images --repository-name $REPO_NAME
```
