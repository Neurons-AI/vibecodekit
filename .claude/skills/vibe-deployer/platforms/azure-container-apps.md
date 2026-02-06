# Azure Container Apps

> Serverless containers trên Azure. Tương tự Cloud Run, Kubernetes-based.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://portal.azure.com |
| **Free tier** | 180K vCPU-seconds, 360K GB-seconds/month |
| **Difficulty** | Trung bình |
| **Best for** | Microservices, event-driven, Azure ecosystem |

---

## Pricing

| Resource | Free Tier | Price |
|----------|-----------|-------|
| **vCPU** | 180K seconds | $0.000024/second |
| **Memory** | 360K GB-seconds | $0.000003/GB-second |
| **Requests** | 2M | $0.40/million |

---

## Prerequisites

```bash
# Install Azure CLI
brew install azure-cli

# Login
az login

# Install Container Apps extension
az extension add --name containerapp --upgrade

# Register provider
az provider register --namespace Microsoft.App
```

---

## Quick Start

### Create Environment

```bash
# Create resource group
az group create --name myapp-rg --location southeastasia

# Create environment
az containerapp env create \
  --name myapp-env \
  --resource-group myapp-rg \
  --location southeastasia
```

### Deploy Container

```bash
az containerapp create \
  --name myapp \
  --resource-group myapp-rg \
  --environment myapp-env \
  --image ghcr.io/username/myapp:latest \
  --target-port 3000 \
  --ingress external \
  --min-replicas 0 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars "NODE_ENV=production"
```

---

## Configuration

### containerapp.yaml

```yaml
properties:
  configuration:
    activeRevisionsMode: Single
    ingress:
      external: true
      targetPort: 3000
      transport: auto
      allowInsecure: false
    secrets:
      - name: database-url
        value: "postgresql://..."
  template:
    containers:
      - name: myapp
        image: ghcr.io/username/myapp:latest
        resources:
          cpu: 0.5
          memory: 1Gi
        env:
          - name: NODE_ENV
            value: production
          - name: DATABASE_URL
            secretRef: database-url
        probes:
          - type: Liveness
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 30
          - type: Readiness
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
    scale:
      minReplicas: 0
      maxReplicas: 10
      rules:
        - name: http-rule
          http:
            metadata:
              concurrentRequests: "100"
```

```bash
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --yaml containerapp.yaml
```

---

## Environment Variables & Secrets

### Environment Variables

```bash
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --set-env-vars "KEY1=value1" "KEY2=value2"
```

### Secrets

```bash
# Create secret
az containerapp secret set \
  --name myapp \
  --resource-group myapp-rg \
  --secrets "database-url=postgresql://..."

# Use secret as env var
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --set-env-vars "DATABASE_URL=secretref:database-url"
```

### Key Vault Integration

```bash
# Reference Key Vault secret
az containerapp secret set \
  --name myapp \
  --resource-group myapp-rg \
  --secrets "db-url=keyvaultref:https://myvault.vault.azure.net/secrets/db-url,identityref:/subscriptions/.../managedIdentities/myidentity"
```

---

## Custom Domain

```bash
# Add custom domain
az containerapp hostname add \
  --name myapp \
  --resource-group myapp-rg \
  --hostname myapp.com

# Bind certificate
az containerapp hostname bind \
  --name myapp \
  --resource-group myapp-rg \
  --hostname myapp.com \
  --certificate-name my-cert
```

### Managed Certificate (Auto SSL)

```bash
az containerapp hostname bind \
  --name myapp \
  --resource-group myapp-rg \
  --hostname myapp.com \
  --validation-method CNAME
```

---

## Scaling

### HTTP Scaling

```bash
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --min-replicas 1 \
  --max-replicas 10 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 100
```

### Custom Scaling (KEDA)

```yaml
# CPU-based
scale:
  rules:
    - name: cpu-rule
      custom:
        type: cpu
        metadata:
          type: Utilization
          value: "70"
```

---

## Dapr Integration

```bash
az containerapp create \
  --name myapp \
  --resource-group myapp-rg \
  --environment myapp-env \
  --image ghcr.io/username/myapp:latest \
  --enable-dapr \
  --dapr-app-id myapp \
  --dapr-app-port 3000
```

---

## Multi-container (Sidecar)

```yaml
template:
  containers:
    - name: myapp
      image: ghcr.io/username/myapp:latest
      resources:
        cpu: 0.5
        memory: 1Gi
    - name: sidecar
      image: nginx:alpine
      resources:
        cpu: 0.25
        memory: 0.5Gi
```

---

## CI/CD

### GitHub Actions

```yaml
name: Deploy to Azure Container Apps

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push
        run: |
          docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .
          docker push ghcr.io/${{ github.repository }}:${{ github.sha }}

      - name: Deploy to Container Apps
        uses: azure/container-apps-deploy-action@v1
        with:
          resourceGroup: myapp-rg
          containerAppName: myapp
          imageToDeploy: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

### Azure DevOps Pipeline

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: 'my-subscription'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az containerapp update \
          --name myapp \
          --resource-group myapp-rg \
          --image ghcr.io/username/myapp:$(Build.SourceVersion)
```

---

## Logs & Monitoring

```bash
# View logs
az containerapp logs show \
  --name myapp \
  --resource-group myapp-rg \
  --type console

# Stream logs
az containerapp logs show \
  --name myapp \
  --resource-group myapp-rg \
  --type console \
  --follow

# System logs
az containerapp logs show \
  --name myapp \
  --resource-group myapp-rg \
  --type system
```

### Log Analytics

```bash
# Query logs
az monitor log-analytics query \
  --workspace WORKSPACE_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'myapp' | limit 100"
```

---

## Revisions & Traffic Split

```bash
# List revisions
az containerapp revision list \
  --name myapp \
  --resource-group myapp-rg

# Split traffic
az containerapp ingress traffic set \
  --name myapp \
  --resource-group myapp-rg \
  --revision-weight myapp--abc123=80 myapp--def456=20
```

---

## Quick Commands

```bash
# === CREATE ===
az containerapp create --name myapp --resource-group myapp-rg --environment myapp-env --image IMAGE

# === UPDATE ===
az containerapp update --name myapp --resource-group myapp-rg --image NEW_IMAGE
az containerapp update --name myapp --resource-group myapp-rg --set-env-vars KEY=value

# === SCALE ===
az containerapp update --name myapp --resource-group myapp-rg --min-replicas 1 --max-replicas 10

# === LOGS ===
az containerapp logs show --name myapp --resource-group myapp-rg --follow

# === SECRETS ===
az containerapp secret set --name myapp --resource-group myapp-rg --secrets "key=value"
az containerapp secret list --name myapp --resource-group myapp-rg

# === REVISIONS ===
az containerapp revision list --name myapp --resource-group myapp-rg
az containerapp revision restart --name myapp --resource-group myapp-rg --revision REVISION_NAME

# === DELETE ===
az containerapp delete --name myapp --resource-group myapp-rg
```
