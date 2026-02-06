# Render

> PaaS với free tier tốt, auto-deploy từ GitHub, managed databases.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://render.com |
| **Free tier** | Yes (với limitations) |
| **Difficulty** | Dễ |
| **Best for** | Side projects, startups, free hosting |

---

## Pricing

| Service Type | Free Tier | Paid |
|--------------|-----------|------|
| **Web Service** | 750 hours/month, sleeps after 15min | $7/month |
| **PostgreSQL** | 90 days, then deleted | $7/month |
| **Redis** | 25MB | $10/month |

> **Note:** Free web services spin down after 15 minutes of inactivity

---

## Deploy Methods

### Method 1: From GitHub

1. Go to https://render.com
2. **New** → **Web Service**
3. Connect GitHub account
4. Select repository
5. Configure:
   - Name: `myapp`
   - Region: Singapore / Oregon
   - Branch: `main`
   - Runtime: **Docker**
6. Add environment variables
7. Click **Create Web Service**

### Method 2: From Docker Registry

1. **New** → **Web Service**
2. Select **Deploy an existing image**
3. Enter image URL: `ghcr.io/username/myapp:latest`
4. Add credentials if private registry
5. Configure and deploy

---

## Configuration

### render.yaml (Infrastructure as Code)

```yaml
services:
  - type: web
    name: myapp
    runtime: docker
    dockerfilePath: ./Dockerfile
    dockerContext: .
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: mydb
          property: connectionString
    healthCheckPath: /health
    autoDeploy: true

databases:
  - name: mydb
    databaseName: myapp
    plan: free # or starter, standard, etc.
```

### Environment Variables

1. Service → **Environment**
2. Add key-value pairs
3. Use **Secret Files** for certificates/keys

---

## Database Setup

### PostgreSQL

1. **New** → **PostgreSQL**
2. Name: `mydb`
3. Region: Same as web service
4. Plan: Free (90 days) or Starter ($7)
5. **Create Database**
6. Copy **Internal Database URL** for your web service

### Linking Database

```yaml
# render.yaml
envVars:
  - key: DATABASE_URL
    fromDatabase:
      name: mydb
      property: connectionString
```

Or manually copy Internal URL to web service environment.

---

## Custom Domain

1. Service → **Settings** → **Custom Domains**
2. Add your domain
3. Update DNS:
   ```
   Type: CNAME
   Name: @ (or subdomain)
   Value: myapp.onrender.com
   ```
4. Render auto-provisions SSL

---

## Dockerfile for Render

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

# Render uses PORT env var
EXPOSE 10000
ENV PORT=10000

CMD ["node", "dist/index.js"]
```

> **Note:** Render uses port 10000 by default, or use `PORT` env var

---

## Health Checks

Set in service settings:
- **Health Check Path:** `/health`

```typescript
// Example health endpoint (Express)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

---

## Auto-deploy

Enabled by default when connected to GitHub.

### Disable auto-deploy
- Service → **Settings** → **Build & Deploy**
- Toggle off **Auto-Deploy**

### Manual deploy
- Click **Manual Deploy** → **Deploy latest commit**

---

## Background Workers

```yaml
# render.yaml
services:
  - type: worker
    name: myworker
    runtime: docker
    dockerfilePath: ./Dockerfile.worker
    envVars:
      - key: QUEUE_URL
        value: redis://...
```

---

## Cron Jobs

```yaml
# render.yaml
services:
  - type: cron
    name: daily-cleanup
    runtime: docker
    schedule: "0 2 * * *"  # Daily at 2 AM
    dockerfilePath: ./Dockerfile.cron
```

---

## Persistent Disks (Paid)

```yaml
services:
  - type: web
    name: myapp
    disk:
      name: uploads
      mountPath: /app/uploads
      sizeGB: 1
```

---

## Private Registry Setup

1. Service → **Settings** → **Docker**
2. **Image URL:** `ghcr.io/username/myapp:latest`
3. **Credentials:**
   - Username: GitHub username
   - Password: Personal Access Token

---

## Logs & Monitoring

### Logs
- Service → **Logs** tab
- Filter by timeframe
- Download logs

### Metrics
- Service → **Metrics** tab
- CPU, Memory, Response times

---

## Preview Environments

Auto-create preview for pull requests:

1. Service → **Settings** → **Preview**
2. Enable **Pull Request Previews**
3. Each PR gets a unique URL

---

## CI/CD with GitHub Actions

Render auto-deploys, but for custom workflows:

```yaml
name: Deploy to Render

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Render Deploy
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.RENDER_API_KEY }}" \
            "https://api.render.com/v1/services/${{ secrets.RENDER_SERVICE_ID }}/deploys"
```

---

## Common Issues

### Free tier spins down

Solution: Use a service like UptimeRobot to ping your app every 14 minutes.

### Build timeout

- Optimize Dockerfile layers
- Use multi-stage builds
- Upgrade to paid plan for longer builds

### Database connection timeout

- Use **Internal URL** (not External)
- Check connection pooling

---

## Quick Reference

```bash
# === RENDER YAML ===
# Deploy: commit render.yaml to repo

# === MANUAL DEPLOY ===
# Dashboard → Service → Manual Deploy

# === LOGS ===
# Dashboard → Service → Logs

# === ENV VARS ===
# Dashboard → Service → Environment
```

---

## Comparison

| Feature | Render | Railway | Heroku |
|---------|--------|---------|--------|
| Free tier | Yes (limited) | $5 credit | No (since 2022) |
| Sleep on free | Yes (15min) | No | N/A |
| Database | 90 days free | Included | Paid |
| Docker | ✅ | ✅ | ✅ |
| Auto-deploy | ✅ | ✅ | ✅ |
| Preview envs | ✅ | ❌ | ✅ |
