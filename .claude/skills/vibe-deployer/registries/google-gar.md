# Google Artifact Registry (GAR)

> Registry của Google Cloud, thay thế cho Container Registry (GCR). Hỗ trợ Docker, npm, Maven, và nhiều hơn.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | `REGION-docker.pkg.dev` |
| **Free tier** | 500MB storage, 1GB egress/month |
| **Image format** | `REGION-docker.pkg.dev/PROJECT_ID/REPO/IMAGE:TAG` |
| **Best for** | GCP deployments, Cloud Run, GKE |

---

## Prerequisites

1. Google Cloud account
2. gcloud CLI installed
3. Billing enabled (required for Artifact Registry)

### Install gcloud CLI

```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash

# Windows
# Download từ https://cloud.google.com/sdk/docs/install
```

### Configure gcloud

```bash
# Login
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Verify
gcloud config list
```

---

## Setup

### 1. Enable API

```bash
gcloud services enable artifactregistry.googleapis.com
```

### 2. Tạo Repository

```bash
# Tạo Docker repository
gcloud artifacts repositories create myrepo \
    --repository-format=docker \
    --location=asia-southeast1 \
    --description="My Docker repository"

# List repositories
gcloud artifacts repositories list
```

### 3. Configure Docker Authentication

```bash
# Configure Docker để dùng gcloud cho auth
gcloud auth configure-docker asia-southeast1-docker.pkg.dev

# Hoặc cho multiple regions
gcloud auth configure-docker \
  asia-southeast1-docker.pkg.dev,us-central1-docker.pkg.dev
```

---

## Usage

### Image Naming

```bash
# Format
REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG

# Example
asia-southeast1-docker.pkg.dev/my-project/myrepo/myapp:latest
```

### Build & Tag

```bash
# Set variables
export PROJECT_ID=my-project
export REGION=asia-southeast1
export REPO=myrepo

# Build
docker build -t myapp:latest .

# Tag
docker tag myapp:latest $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:latest
docker tag myapp:latest $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:v1.0.0
```

### Push

```bash
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:latest
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:v1.0.0
```

### Pull

```bash
docker pull $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:latest
```

---

## Cloud Build Integration

### cloudbuild.yaml

```yaml
steps:
  # Build image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_IMAGE}:${SHORT_SHA}'
      - '-t'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_IMAGE}:latest'
      - '.'

  # Push image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - '--all-tags'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_IMAGE}'

substitutions:
  _REGION: asia-southeast1
  _REPO: myrepo
  _IMAGE: myapp

images:
  - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_IMAGE}'
```

### Trigger build

```bash
# Manual trigger
gcloud builds submit --config=cloudbuild.yaml .

# Setup trigger (on push to main)
gcloud builds triggers create github \
  --repo-name=myrepo \
  --repo-owner=myorg \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

---

## GitHub Actions Integration

```yaml
name: Build and Push to GAR

on:
  push:
    branches: [main]

env:
  PROJECT_ID: my-project
  REGION: asia-southeast1
  REPO: myrepo
  IMAGE: myapp

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Google Auth
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Configure Docker
        run: gcloud auth configure-docker ${{ env.REGION }}-docker.pkg.dev

      - name: Build and Push
        run: |
          docker build -t ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO }}/${{ env.IMAGE }}:${{ github.sha }} .
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO }}/${{ env.IMAGE }}:${{ github.sha }}
          docker tag ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO }}/${{ env.IMAGE }}:${{ github.sha }} \
                     ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO }}/${{ env.IMAGE }}:latest
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO }}/${{ env.IMAGE }}:latest
```

---

## IAM Permissions

### Roles

| Role | Description |
|------|-------------|
| `roles/artifactregistry.reader` | Pull images |
| `roles/artifactregistry.writer` | Push images |
| `roles/artifactregistry.admin` | Full access |

### Grant access

```bash
# Grant push access to service account
gcloud artifacts repositories add-iam-policy-binding myrepo \
  --location=asia-southeast1 \
  --member=serviceAccount:my-sa@my-project.iam.gserviceaccount.com \
  --role=roles/artifactregistry.writer
```

---

## Cleanup Policies

### Delete old images

```bash
# List images
gcloud artifacts docker images list \
  $REGION-docker.pkg.dev/$PROJECT_ID/$REPO

# Delete specific image
gcloud artifacts docker images delete \
  $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:old-tag
```

### Automated cleanup policy

```bash
gcloud artifacts repositories set-cleanup-policies myrepo \
  --location=asia-southeast1 \
  --policy=cleanup-policy.json
```

```json
// cleanup-policy.json
[
  {
    "name": "delete-old-images",
    "action": {"type": "Delete"},
    "condition": {
      "olderThan": "30d"
    }
  },
  {
    "name": "keep-minimum",
    "action": {"type": "Keep"},
    "mostRecentVersions": {
      "keepCount": 5
    }
  }
]
```

---

## Vulnerability Scanning

### Enable scanning

```bash
# Enable Container Analysis API
gcloud services enable containeranalysis.googleapis.com

# Scanning is automatic when pushing to GAR
```

### View vulnerabilities

```bash
gcloud artifacts docker images list \
  $REGION-docker.pkg.dev/$PROJECT_ID/$REPO \
  --show-occurrences
```

---

## Multi-region Setup

```bash
# Create repos in multiple regions
gcloud artifacts repositories create myrepo \
    --repository-format=docker \
    --location=asia-southeast1

gcloud artifacts repositories create myrepo \
    --repository-format=docker \
    --location=us-central1

# Configure Docker for all regions
gcloud auth configure-docker \
  asia-southeast1-docker.pkg.dev,us-central1-docker.pkg.dev
```

---

## Migrate from GCR

```bash
# GCR format (old)
gcr.io/PROJECT_ID/IMAGE:TAG

# GAR format (new)
REGION-docker.pkg.dev/PROJECT_ID/REPO/IMAGE:TAG
```

### Copy images from GCR to GAR

```bash
# Using gcrane
gcrane cp gcr.io/my-project/myapp:latest \
  asia-southeast1-docker.pkg.dev/my-project/myrepo/myapp:latest
```

---

## Pricing

| Item | Price |
|------|-------|
| **Storage** | $0.10/GB/month |
| **Egress (same region)** | Free |
| **Egress (cross region)** | $0.01/GB |
| **Free Tier** | 500MB storage, 1GB egress |

---

## Troubleshooting

### "Permission denied"

```bash
# Re-authenticate
gcloud auth login
gcloud auth configure-docker REGION-docker.pkg.dev
```

### "Repository not found"

```bash
# Kiểm tra repository tồn tại
gcloud artifacts repositories list --location=REGION

# Tạo nếu chưa có
gcloud artifacts repositories create REPO \
  --repository-format=docker \
  --location=REGION
```

### "Billing not enabled"

```bash
# Enable billing in GCP Console
# https://console.cloud.google.com/billing
```

---

## Quick Commands

```bash
# === SETUP ===
export PROJECT_ID=$(gcloud config get-value project)
export REGION=asia-southeast1
export REPO=myrepo

# === CREATE REPO ===
gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION

# === CONFIGURE DOCKER ===
gcloud auth configure-docker $REGION-docker.pkg.dev

# === BUILD & PUSH ===
docker build -t myapp:latest .
docker tag myapp:latest $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:latest
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/myapp:latest

# === LIST IMAGES ===
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$REPO
```
