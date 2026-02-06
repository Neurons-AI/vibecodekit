# AWS Lightsail Containers

> Simple container deployment trên AWS. Dễ dùng hơn ECS, giá cố định.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://lightsail.aws.amazon.com |
| **Free tier** | 3 months free (nano plan) |
| **Difficulty** | Dễ |
| **Best for** | Simple apps, predictable pricing, beginners to AWS |

---

## Pricing (Fixed)

| Plan | vCPU | RAM | Price |
|------|------|-----|-------|
| Nano | 0.25 | 512MB | $7/month |
| Micro | 0.5 | 1GB | $10/month |
| Small | 1 | 2GB | $25/month |
| Medium | 2 | 4GB | $50/month |
| Large | 4 | 8GB | $100/month |

> Includes: Data transfer, HTTPS endpoint

---

## Deploy via Console

1. Go to **Lightsail** → **Containers**
2. Click **Create container service**
3. Configure:
   - Region: Select nearest
   - Capacity: Choose plan
   - Scale: Number of nodes (1-20)
4. **Set up deployment**
   - Image source: **Specify a custom image**
   - Image: `ghcr.io/username/myapp:latest`
   - Add registry credentials if private
5. Configure ports and health check
6. Add environment variables
7. **Create container service**

---

## Deploy via AWS CLI

### Create Container Service

```bash
aws lightsail create-container-service \
  --service-name myapp \
  --power nano \
  --scale 1 \
  --region ap-southeast-1
```

### Push Image to Lightsail

```bash
# Build image
docker build -t myapp:latest .

# Push to Lightsail
aws lightsail push-container-image \
  --service-name myapp \
  --label myapp \
  --image myapp:latest \
  --region ap-southeast-1

# Note the image name returned (e.g., :myapp.myapp.1)
```

### Create Deployment

```json
// containers.json
{
  "myapp": {
    "image": ":myapp.myapp.1",
    "ports": {
      "3000": "HTTP"
    },
    "environment": {
      "NODE_ENV": "production",
      "DATABASE_URL": "postgresql://..."
    }
  }
}
```

```json
// public-endpoint.json
{
  "containerName": "myapp",
  "containerPort": 3000,
  "healthCheck": {
    "path": "/health",
    "intervalSeconds": 30,
    "timeoutSeconds": 5,
    "healthyThreshold": 2,
    "unhealthyThreshold": 3
  }
}
```

```bash
aws lightsail create-container-service-deployment \
  --service-name myapp \
  --containers file://containers.json \
  --public-endpoint file://public-endpoint.json
```

---

## Using External Registry

### GitHub Container Registry

```bash
# Create deployment with GHCR image
aws lightsail create-container-service-deployment \
  --service-name myapp \
  --containers '{
    "myapp": {
      "image": "ghcr.io/username/myapp:latest",
      "ports": {"3000": "HTTP"},
      "environment": {"NODE_ENV": "production"}
    }
  }' \
  --public-endpoint '{
    "containerName": "myapp",
    "containerPort": 3000
  }'
```

### Private Registry Credentials

```bash
# Register credentials
aws lightsail register-container-image \
  --service-name myapp \
  --label myapp \
  --image ghcr.io/username/myapp:latest

# Or via console: Add private registry credentials
```

---

## Custom Domain

### Via Console

1. Container service → **Custom domains**
2. **Create certificate**
3. Add domain names
4. Validate via DNS
5. **Attach certificate**

### Via CLI

```bash
# Create certificate
aws lightsail create-certificate \
  --certificate-name myapp-cert \
  --domain-name myapp.com \
  --subject-alternative-names www.myapp.com

# After DNS validation
aws lightsail attach-certificate-to-distribution \
  --distribution-name myapp-dist \
  --certificate-name myapp-cert
```

---

## Scaling

```bash
# Scale nodes
aws lightsail update-container-service \
  --service-name myapp \
  --scale 3

# Change power (plan)
aws lightsail update-container-service \
  --service-name myapp \
  --power small
```

---

## Environment Variables

### Update deployment

```bash
aws lightsail create-container-service-deployment \
  --service-name myapp \
  --containers '{
    "myapp": {
      "image": ":myapp.myapp.1",
      "ports": {"3000": "HTTP"},
      "environment": {
        "NODE_ENV": "production",
        "DATABASE_URL": "postgresql://...",
        "SECRET_KEY": "mysecret"
      }
    }
  }' \
  --public-endpoint '{
    "containerName": "myapp",
    "containerPort": 3000
  }'
```

---

## Health Checks

```json
// public-endpoint.json
{
  "containerName": "myapp",
  "containerPort": 3000,
  "healthCheck": {
    "path": "/health",
    "intervalSeconds": 30,
    "timeoutSeconds": 5,
    "healthyThreshold": 2,
    "unhealthyThreshold": 3,
    "successCodes": "200-299"
  }
}
```

---

## Logs

### Via Console

Container service → **Logs** tab

### Via CLI

```bash
aws lightsail get-container-log \
  --service-name myapp \
  --container-name myapp \
  --start-time 2024-01-01T00:00:00Z
```

---

## CI/CD with GitHub Actions

```yaml
name: Deploy to Lightsail

on:
  push:
    branches: [main]

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
          aws-region: ap-southeast-1

      - name: Install Lightsail plugin
        run: |
          curl "https://s3.us-west-2.amazonaws.com/lightsailctl/latest/linux-amd64/lightsailctl" -o "/usr/local/bin/lightsailctl"
          chmod +x /usr/local/bin/lightsailctl

      - name: Build Docker image
        run: docker build -t myapp:latest .

      - name: Push to Lightsail
        run: |
          aws lightsail push-container-image \
            --service-name myapp \
            --label myapp \
            --image myapp:latest

      - name: Get pushed image
        id: image
        run: |
          IMAGE=$(aws lightsail get-container-images --service-name myapp --query 'containerImages[0].image' --output text)
          echo "image=$IMAGE" >> $GITHUB_OUTPUT

      - name: Deploy
        run: |
          aws lightsail create-container-service-deployment \
            --service-name myapp \
            --containers '{
              "myapp": {
                "image": "${{ steps.image.outputs.image }}",
                "ports": {"3000": "HTTP"},
                "environment": {"NODE_ENV": "production"}
              }
            }' \
            --public-endpoint '{
              "containerName": "myapp",
              "containerPort": 3000,
              "healthCheck": {"path": "/health"}
            }'
```

---

## Database

Lightsail also offers managed databases:

```bash
# Create PostgreSQL
aws lightsail create-relational-database \
  --relational-database-name myapp-db \
  --relational-database-blueprint-id postgres_16 \
  --relational-database-bundle-id micro_2_0 \
  --master-username admin \
  --master-user-password "SecurePassword123!"
```

---

## Comparison with ECS

| Feature | Lightsail | ECS Fargate |
|---------|-----------|-------------|
| Pricing | Fixed | Pay-per-use |
| Complexity | Simple | Complex |
| Scaling | Manual (1-20) | Auto-scaling |
| Networking | Simple | VPC, ALB, etc. |
| Best for | Simple apps | Enterprise |

---

## Quick Commands

```bash
# === SERVICE ===
aws lightsail create-container-service --service-name myapp --power nano --scale 1
aws lightsail get-container-services --service-name myapp
aws lightsail update-container-service --service-name myapp --scale 2
aws lightsail delete-container-service --service-name myapp

# === IMAGES ===
aws lightsail push-container-image --service-name myapp --label app --image myapp:latest
aws lightsail get-container-images --service-name myapp

# === DEPLOYMENT ===
aws lightsail create-container-service-deployment --service-name myapp --containers file://containers.json --public-endpoint file://endpoint.json
aws lightsail get-container-service-deployments --service-name myapp

# === LOGS ===
aws lightsail get-container-log --service-name myapp --container-name myapp
```
