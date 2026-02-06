# Azure Container Registry (ACR)

> Registry của Microsoft Azure, tích hợp tốt với Azure services như AKS, App Service, Container Apps.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | `REGISTRY_NAME.azurecr.io` |
| **Free tier** | Không có (Basic ~$5/month) |
| **Image format** | `REGISTRY_NAME.azurecr.io/IMAGE:TAG` |
| **Best for** | Azure deployments, enterprise, Windows containers |

---

## Prerequisites

1. Azure Account
2. Azure CLI installed

### Install Azure CLI

```bash
# macOS
brew install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
# Download từ https://aka.ms/installazurecliwindows
```

### Login to Azure

```bash
az login
```

---

## Setup

### 1. Tạo Resource Group

```bash
az group create \
  --name myResourceGroup \
  --location southeastasia
```

### 2. Tạo Container Registry

```bash
# Basic tier
az acr create \
  --resource-group myResourceGroup \
  --name myregistry \
  --sku Basic

# Standard tier (recommended for production)
az acr create \
  --resource-group myResourceGroup \
  --name myregistry \
  --sku Standard
```

### 3. Login vào ACR

```bash
# Login với Azure CLI (recommended)
az acr login --name myregistry

# Hoặc với Docker
docker login myregistry.azurecr.io
```

---

## Usage

### Build & Tag

```bash
# Set variable
export ACR_NAME=myregistry

# Build
docker build -t myapp:latest .

# Tag
docker tag myapp:latest $ACR_NAME.azurecr.io/myapp:latest
docker tag myapp:latest $ACR_NAME.azurecr.io/myapp:v1.0.0
```

### Push

```bash
docker push $ACR_NAME.azurecr.io/myapp:latest
docker push $ACR_NAME.azurecr.io/myapp:v1.0.0
```

### Pull

```bash
docker pull $ACR_NAME.azurecr.io/myapp:latest
```

---

## ACR Tasks (Cloud Build)

### Build in cloud

```bash
# Build từ local Dockerfile
az acr build \
  --registry myregistry \
  --image myapp:latest .

# Build từ GitHub
az acr build \
  --registry myregistry \
  --image myapp:latest \
  https://github.com/user/repo.git
```

### Quick tasks

```yaml
# acr-task.yaml
version: v1.1.0
steps:
  - build: -t $Registry/myapp:$Run.ID .
  - push:
    - $Registry/myapp:$Run.ID
    - $Registry/myapp:latest
```

```bash
az acr run --registry myregistry --file acr-task.yaml .
```

---

## Authentication Methods

### 1. Azure CLI (Development)

```bash
az acr login --name myregistry
```

### 2. Service Principal (CI/CD)

```bash
# Tạo service principal
ACR_REGISTRY_ID=$(az acr show --name myregistry --query id --output tsv)

az ad sp create-for-rbac \
  --name myregistry-sp \
  --scopes $ACR_REGISTRY_ID \
  --role acrpush \
  --query password \
  --output tsv

# Lưu App ID và Password
# Login với SP
docker login myregistry.azurecr.io \
  --username <APP_ID> \
  --password <PASSWORD>
```

### 3. Admin User (Simple, không recommended cho production)

```bash
# Enable admin user
az acr update --name myregistry --admin-enabled true

# Get credentials
az acr credential show --name myregistry

# Login
docker login myregistry.azurecr.io \
  --username myregistry \
  --password <PASSWORD>
```

---

## GitHub Actions Integration

```yaml
name: Build and Push to ACR

on:
  push:
    branches: [main]

env:
  ACR_NAME: myregistry

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Login to ACR
        run: az acr login --name ${{ env.ACR_NAME }}

      - name: Build and Push
        run: |
          docker build -t ${{ env.ACR_NAME }}.azurecr.io/myapp:${{ github.sha }} .
          docker push ${{ env.ACR_NAME }}.azurecr.io/myapp:${{ github.sha }}
          docker tag ${{ env.ACR_NAME }}.azurecr.io/myapp:${{ github.sha }} \
                     ${{ env.ACR_NAME }}.azurecr.io/myapp:latest
          docker push ${{ env.ACR_NAME }}.azurecr.io/myapp:latest
```

### Tạo AZURE_CREDENTIALS

```bash
az ad sp create-for-rbac \
  --name "github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth

# Copy output JSON vào GitHub secret AZURE_CREDENTIALS
```

---

## Geo-replication

```bash
# Enable geo-replication (Premium SKU required)
az acr replication create \
  --registry myregistry \
  --location westeurope

# List replications
az acr replication list --registry myregistry
```

---

## Security Features

### Content Trust (Image Signing)

```bash
# Enable
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER=https://myregistry.azurecr.io

# Push signed image
docker push myregistry.azurecr.io/myapp:latest
```

### Vulnerability Scanning

```bash
# Enable Microsoft Defender
az security pricing create \
  --name ContainerRegistry \
  --tier Standard

# View scan results in Azure Portal
```

### Private Link

```bash
# Create private endpoint
az network private-endpoint create \
  --name myPrivateEndpoint \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --subnet mySubnet \
  --private-connection-resource-id $(az acr show --name myregistry --query id --output tsv) \
  --group-id registry \
  --connection-name myConnection
```

---

## Cleanup & Retention

### Delete images

```bash
# Delete specific tag
az acr repository delete \
  --name myregistry \
  --image myapp:old-tag

# Delete entire repository
az acr repository delete \
  --name myregistry \
  --repository myapp
```

### Retention policy

```bash
# Set retention policy (Premium SKU)
az acr config retention update \
  --registry myregistry \
  --status enabled \
  --days 30 \
  --type UntaggedManifests
```

### Purge old images

```bash
# Purge images older than 30 days
az acr run \
  --cmd "acr purge --filter 'myapp:.*' --ago 30d --untagged" \
  --registry myregistry \
  /dev/null
```

---

## Pricing

| SKU | Storage | Price/month |
|-----|---------|-------------|
| **Basic** | 10GB | ~$5 |
| **Standard** | 100GB | ~$20 |
| **Premium** | 500GB | ~$50 |

> Premium includes: Geo-replication, Content Trust, Private Link

---

## Troubleshooting

### "unauthorized: authentication required"

```bash
# Re-login
az acr login --name myregistry

# Hoặc với Docker
az acr credential show --name myregistry
docker login myregistry.azurecr.io
```

### "denied: requested access is denied"

```bash
# Kiểm tra role assignment
az role assignment list --assignee <SP_APP_ID> --scope $(az acr show --name myregistry --query id -o tsv)

# Grant acrpush role
az role assignment create \
  --assignee <SP_APP_ID> \
  --role acrpush \
  --scope $(az acr show --name myregistry --query id -o tsv)
```

### "repository does not exist"

```bash
# List repositories
az acr repository list --name myregistry

# Kiểm tra đúng tên
```

---

## Quick Commands

```bash
# === SETUP ===
export ACR_NAME=myregistry
export RG_NAME=myResourceGroup

# === CREATE ===
az group create --name $RG_NAME --location southeastasia
az acr create --resource-group $RG_NAME --name $ACR_NAME --sku Basic

# === LOGIN ===
az acr login --name $ACR_NAME

# === BUILD & PUSH ===
docker build -t myapp:latest .
docker tag myapp:latest $ACR_NAME.azurecr.io/myapp:latest
docker push $ACR_NAME.azurecr.io/myapp:latest

# === OR BUILD IN CLOUD ===
az acr build --registry $ACR_NAME --image myapp:latest .

# === LIST IMAGES ===
az acr repository list --name $ACR_NAME
az acr repository show-tags --name $ACR_NAME --repository myapp
```
