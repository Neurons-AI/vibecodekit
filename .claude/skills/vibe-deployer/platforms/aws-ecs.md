# AWS ECS (Elastic Container Service)

> Container orchestration của AWS. Enterprise-grade, highly scalable.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://console.aws.amazon.com/ecs |
| **Free tier** | Limited (Fargate không free) |
| **Difficulty** | Khó |
| **Best for** | Enterprise, high scale, AWS ecosystem |

---

## Concepts

| Term | Description |
|------|-------------|
| **Cluster** | Logical grouping of services |
| **Service** | Maintains desired count of tasks |
| **Task Definition** | Blueprint for containers |
| **Task** | Running instance of task definition |
| **Fargate** | Serverless compute for containers |
| **EC2** | Self-managed EC2 instances |

---

## Prerequisites

```bash
# Install AWS CLI
brew install awscli

# Configure
aws configure

# Install ECS CLI (optional)
brew install amazon-ecs-cli
```

---

## Quick Start with Fargate

### 1. Create Cluster

```bash
aws ecs create-cluster --cluster-name myapp-cluster
```

### 2. Create Task Definition

```json
// task-definition.json
{
  "family": "myapp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "myapp",
      "image": "ACCOUNT.dkr.ecr.REGION.amazonaws.com/myapp:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:myapp/database-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/myapp",
          "awslogs-region": "ap-southeast-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "wget -qO- http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

### 3. Create Service

```bash
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-service \
  --task-definition myapp:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=myapp,containerPort=3000"
```

---

## Using Copilot CLI (Recommended)

AWS Copilot simplifies ECS deployment.

### Install

```bash
brew install aws/tap/copilot-cli
```

### Initialize

```bash
# Init application
copilot init

# Follow prompts:
# - Application name: myapp
# - Service type: Load Balanced Web Service
# - Service name: api
# - Dockerfile: ./Dockerfile
```

### Deploy

```bash
copilot deploy
```

### Copilot Manifest

```yaml
# copilot/api/manifest.yml
name: api
type: Load Balanced Web Service

image:
  build: Dockerfile
  port: 3000

http:
  path: '/'
  healthcheck:
    path: '/health'
    interval: 30s
    timeout: 5s
    healthy_threshold: 2
    unhealthy_threshold: 3

cpu: 256
memory: 512
count: 2

variables:
  NODE_ENV: production

secrets:
  DATABASE_URL: /myapp/production/database-url

exec: true  # Enable ECS Exec for debugging
```

### Copilot Commands

```bash
copilot svc deploy           # Deploy service
copilot svc logs             # View logs
copilot svc status           # Check status
copilot svc exec             # Shell into container
copilot env deploy           # Deploy environment
copilot app delete           # Delete everything
```

---

## Load Balancer Setup

### Application Load Balancer (ALB)

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name myapp-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx

# Create Target Group
aws elbv2 create-target-group \
  --name myapp-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-xxx \
  --target-type ip \
  --health-check-path /health

# Create Listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

---

## Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 10

# Create scaling policy (CPU based)
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    }
  }'
```

---

## Secrets Management

### Using Secrets Manager

```bash
# Create secret
aws secretsmanager create-secret \
  --name myapp/database-url \
  --secret-string "postgresql://user:pass@host:5432/db"
```

### In Task Definition

```json
"secrets": [
  {
    "name": "DATABASE_URL",
    "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:myapp/database-url"
  }
]
```

---

## CI/CD with GitHub Actions

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

env:
  AWS_REGION: ap-southeast-1
  ECR_REPOSITORY: myapp
  ECS_SERVICE: myapp-service
  ECS_CLUSTER: myapp-cluster
  ECS_TASK_DEFINITION: task-definition.json
  CONTAINER_NAME: myapp

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

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
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

      - name: Fill in image ID in task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ${{ env.ECS_TASK_DEFINITION }}
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ steps.build-image.outputs.image }}

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
```

---

## Monitoring

### CloudWatch Logs

```bash
# View logs
aws logs get-log-events \
  --log-group-name /ecs/myapp \
  --log-stream-name ecs/myapp/TASK_ID
```

### CloudWatch Metrics

- CPUUtilization
- MemoryUtilization
- RunningTaskCount

---

## Debugging

### ECS Exec (SSH into container)

```bash
# Enable in service
aws ecs update-service \
  --cluster myapp-cluster \
  --service myapp-service \
  --enable-execute-command

# Execute command
aws ecs execute-command \
  --cluster myapp-cluster \
  --task TASK_ID \
  --container myapp \
  --interactive \
  --command "/bin/sh"
```

---

## Pricing

| Resource | Price |
|----------|-------|
| **Fargate vCPU** | $0.04048/hour |
| **Fargate Memory** | $0.004445/GB/hour |
| **EC2** | EC2 instance pricing |
| **ALB** | $0.0225/hour + LCU |

---

## Quick Commands

```bash
# === CLUSTERS ===
aws ecs list-clusters
aws ecs describe-clusters --clusters myapp-cluster

# === SERVICES ===
aws ecs list-services --cluster myapp-cluster
aws ecs describe-services --cluster myapp-cluster --services myapp-service
aws ecs update-service --cluster myapp-cluster --service myapp-service --desired-count 3

# === TASKS ===
aws ecs list-tasks --cluster myapp-cluster
aws ecs describe-tasks --cluster myapp-cluster --tasks TASK_ARN

# === LOGS ===
aws logs tail /ecs/myapp --follow

# === COPILOT ===
copilot svc deploy
copilot svc logs
copilot svc status
```
