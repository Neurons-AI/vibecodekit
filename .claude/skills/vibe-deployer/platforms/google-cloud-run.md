# Google Cloud Run

> Serverless containers trên GCP. Pay-per-request, auto-scales to zero.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://console.cloud.google.com/run |
| **Free tier** | 2M requests/month, 360K GB-seconds |
| **Difficulty** | Dễ - Trung bình |
| **Best for** | Serverless, auto-scaling, pay-per-use |

---

## Pricing

| Resource | Free Tier | Price |
|----------|-----------|-------|
| **Requests** | 2M/month | $0.40/million |
| **CPU** | 180K vCPU-seconds | $0.00002400/vCPU-second |
| **Memory** | 360K GB-seconds | $0.00000250/GB-second |
| **Networking** | 1GB egress | $0.12/GB |

> Containers scale to zero = no charge when idle

---

## Prerequisites

```bash
# Install gcloud CLI
brew install google-cloud-sdk

# Login
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable APIs
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

---

## Deploy Methods

### Method 1: From Source (Buildpacks)

```bash
# Deploy directly from source
gcloud run deploy myapp \
  --source . \
  --region asia-southeast1 \
  --allow-unauthenticated
```

### Method 2: From Dockerfile

```bash
# Build and push to Artifact Registry
gcloud builds submit --tag asia-southeast1-docker.pkg.dev/PROJECT/REPO/myapp

# Deploy
gcloud run deploy myapp \
  --image asia-southeast1-docker.pkg.dev/PROJECT/REPO/myapp \
  --region asia-southeast1 \
  --allow-unauthenticated
```

### Method 3: From Container Registry

```bash
gcloud run deploy myapp \
  --image ghcr.io/username/myapp:latest \
  --region asia-southeast1 \
  --allow-unauthenticated
```

---

## Configuration

### service.yaml

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "0"
        autoscaling.knative.dev/maxScale: "10"
    spec:
      containerConcurrency: 80
      timeoutSeconds: 300
      containers:
        - image: asia-southeast1-docker.pkg.dev/PROJECT/REPO/myapp
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
          resources:
            limits:
              cpu: "1"
              memory: 512Mi
```

```bash
gcloud run services replace service.yaml --region asia-southeast1
```

### CLI Configuration

```bash
gcloud run deploy myapp \
  --image IMAGE_URL \
  --region asia-southeast1 \
  --platform managed \
  --allow-unauthenticated \
  --port 3000 \
  --cpu 1 \
  --memory 512Mi \
  --min-instances 0 \
  --max-instances 10 \
  --concurrency 80 \
  --timeout 300 \
  --set-env-vars "NODE_ENV=production,LOG_LEVEL=info" \
  --set-secrets "DATABASE_URL=database-url:latest"
```

---

## Environment Variables

### Set via CLI

```bash
# Set env vars
gcloud run services update myapp \
  --set-env-vars "KEY1=value1,KEY2=value2"

# Update single var
gcloud run services update myapp \
  --update-env-vars "KEY1=newvalue"
```

### Using Secret Manager

```bash
# Create secret
echo -n "postgresql://..." | gcloud secrets create database-url --data-file=-

# Use in Cloud Run
gcloud run services update myapp \
  --set-secrets "DATABASE_URL=database-url:latest"
```

---

## Custom Domain

```bash
# Map custom domain
gcloud run domain-mappings create \
  --service myapp \
  --domain myapp.com \
  --region asia-southeast1
```

Update DNS with provided records.

---

## Auto-scaling

```bash
# Configure scaling
gcloud run services update myapp \
  --min-instances 0 \
  --max-instances 100 \
  --concurrency 80
```

| Parameter | Description |
|-----------|-------------|
| min-instances | Minimum warm instances (0 = scale to zero) |
| max-instances | Maximum instances |
| concurrency | Requests per instance |

---

## VPC Connector (Private Network)

```bash
# Create connector
gcloud compute networks vpc-access connectors create myconnector \
  --region asia-southeast1 \
  --network default \
  --range 10.8.0.0/28

# Use connector
gcloud run services update myapp \
  --vpc-connector myconnector \
  --vpc-egress private-ranges-only
```

---

## Cloud SQL Connection

```bash
gcloud run services update myapp \
  --add-cloudsql-instances PROJECT:REGION:INSTANCE \
  --set-env-vars "DATABASE_URL=postgresql://user:pass@/dbname?host=/cloudsql/PROJECT:REGION:INSTANCE"
```

---

## CI/CD with Cloud Build

### cloudbuild.yaml

```yaml
steps:
  # Build image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'asia-southeast1-docker.pkg.dev/$PROJECT_ID/myrepo/myapp:$SHORT_SHA'
      - '.'

  # Push image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - 'asia-southeast1-docker.pkg.dev/$PROJECT_ID/myrepo/myapp:$SHORT_SHA'

  # Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'myapp'
      - '--image'
      - 'asia-southeast1-docker.pkg.dev/$PROJECT_ID/myrepo/myapp:$SHORT_SHA'
      - '--region'
      - 'asia-southeast1'
      - '--allow-unauthenticated'

images:
  - 'asia-southeast1-docker.pkg.dev/$PROJECT_ID/myrepo/myapp:$SHORT_SHA'
```

### GitHub Actions

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [main]

env:
  PROJECT_ID: my-project
  REGION: asia-southeast1
  SERVICE: myapp

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Google Auth
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker
        run: gcloud auth configure-docker ${{ env.REGION }}-docker.pkg.dev

      - name: Build and Push
        run: |
          docker build -t ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/myrepo/myapp:${{ github.sha }} .
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/myrepo/myapp:${{ github.sha }}

      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy ${{ env.SERVICE }} \
            --image ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/myrepo/myapp:${{ github.sha }} \
            --region ${{ env.REGION }} \
            --allow-unauthenticated
```

---

## Logs & Monitoring

```bash
# View logs
gcloud run services logs read myapp --region asia-southeast1

# Tail logs
gcloud run services logs tail myapp --region asia-southeast1

# Or in Cloud Logging
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=myapp" --limit 100
```

---

## Authentication

### Public (anyone can access)

```bash
gcloud run deploy myapp --allow-unauthenticated
```

### Private (authenticated only)

```bash
gcloud run deploy myapp --no-allow-unauthenticated

# Grant access
gcloud run services add-iam-policy-binding myapp \
  --member="user:email@example.com" \
  --role="roles/run.invoker"
```

---

## Dockerfile Requirements

```dockerfile
FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Cloud Run sets PORT environment variable
ENV PORT=8080
EXPOSE 8080

# Must listen on 0.0.0.0
CMD ["node", "server.js"]
```

> **Important:** Cloud Run sets `PORT` env var (default 8080). Listen on `0.0.0.0`.

---

## Quick Commands

```bash
# === DEPLOY ===
gcloud run deploy myapp --source . --region REGION
gcloud run deploy myapp --image IMAGE --region REGION

# === UPDATE ===
gcloud run services update myapp --region REGION --set-env-vars KEY=value
gcloud run services update myapp --region REGION --memory 1Gi

# === STATUS ===
gcloud run services list
gcloud run services describe myapp --region REGION
gcloud run revisions list --service myapp --region REGION

# === LOGS ===
gcloud run services logs read myapp --region REGION
gcloud run services logs tail myapp --region REGION

# === TRAFFIC ===
gcloud run services update-traffic myapp --to-latest --region REGION
gcloud run services update-traffic myapp --to-revisions myapp-00001=50,myapp-00002=50

# === DELETE ===
gcloud run services delete myapp --region REGION
```

---

## Comparison

| Feature | Cloud Run | App Engine | GKE |
|---------|-----------|------------|-----|
| Scale to zero | ✅ | ✅ (Flex) | ❌ |
| Docker | ✅ | Limited | ✅ |
| Pricing | Pay-per-request | Pay-per-hour | Pay-per-node |
| Complexity | Low | Low | High |
| Best for | Serverless | Apps | Kubernetes |
