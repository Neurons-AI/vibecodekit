# DigitalOcean App Platform

> Managed PaaS từ DigitalOcean, deploy từ GitHub hoặc Docker registry.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://cloud.digitalocean.com/apps |
| **Free tier** | 3 static sites |
| **Difficulty** | Dễ |
| **Best for** | Simple deployments, DO ecosystem |

---

## Pricing

| Type | Price |
|------|-------|
| **Basic** | $5/month (512MB, 1 vCPU) |
| **Professional** | $12/month (1GB, 1 vCPU) |
| **Static Sites** | Free (3 sites) |
| **Database** | From $15/month |

---

## Deploy from GitHub

1. Go to **Apps** → **Create App**
2. Select **GitHub**
3. Authorize and select repository
4. Configure:
   - Branch: `main`
   - Source Directory: `/`
   - Autodeploy: On
5. Select **Dockerfile** as build method
6. Choose plan and region
7. Add environment variables
8. Click **Create Resources**

---

## Deploy from Docker Registry

1. **Create App** → **Docker Hub** or **DOCR**
2. Enter image: `ghcr.io/username/myapp:latest`
3. Add registry credentials
4. Configure and deploy

---

## App Spec (app.yaml)

```yaml
name: myapp
region: sgp  # Singapore

services:
  - name: api
    dockerfile_path: Dockerfile
    github:
      repo: username/myapp
      branch: main
      deploy_on_push: true
    http_port: 3000
    instance_count: 1
    instance_size_slug: basic-xxs
    routes:
      - path: /
    envs:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        scope: RUN_TIME
        value: ${db.DATABASE_URL}
    health_check:
      http_path: /health

databases:
  - name: db
    engine: PG
    production: false
    version: "16"
```

### Deploy with doctl

```bash
# Install doctl
brew install doctl

# Auth
doctl auth init

# Deploy
doctl apps create --spec app.yaml

# Update
doctl apps update APP_ID --spec app.yaml
```

---

## Environment Variables

### Via UI
1. App → **Settings** → **App-Level Environment Variables**
2. Add variables

### Via app.yaml
```yaml
envs:
  - key: SECRET_KEY
    value: "mysecret"
    scope: RUN_TIME
    type: SECRET
  - key: NODE_ENV
    value: "production"
    scope: RUN_AND_BUILD_TIME
```

---

## Database

### Managed PostgreSQL

1. App → **Create** → **Database**
2. Select **PostgreSQL**
3. Choose plan
4. Create

### Link to App

```yaml
# app.yaml
envs:
  - key: DATABASE_URL
    scope: RUN_TIME
    value: ${db.DATABASE_URL}

databases:
  - name: db
    engine: PG
    version: "16"
```

---

## Custom Domain

1. App → **Settings** → **Domains**
2. **Add Domain**
3. Enter domain name
4. Update DNS:
   ```
   Type: CNAME
   Name: @
   Value: myapp-xxxxx.ondigitalocean.app
   ```
5. SSL auto-provisioned

---

## Health Checks

```yaml
# app.yaml
services:
  - name: api
    health_check:
      http_path: /health
      initial_delay_seconds: 10
      period_seconds: 10
      timeout_seconds: 5
      success_threshold: 1
      failure_threshold: 3
```

---

## Scaling

### Via UI
App → **Settings** → **Scaling**

### Via app.yaml
```yaml
services:
  - name: api
    instance_count: 3
    instance_size_slug: professional-xs
```

### Instance Sizes

| Slug | vCPU | RAM | Price |
|------|------|-----|-------|
| basic-xxs | 1 | 512MB | $5 |
| basic-xs | 1 | 1GB | $10 |
| professional-xs | 1 | 1GB | $12 |
| professional-s | 1 | 2GB | $25 |

---

## CI/CD

Auto-deploy on push is enabled by default.

### Manual Deploy

```bash
doctl apps create-deployment APP_ID
```

### GitHub Actions

```yaml
name: Deploy to DO

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger deployment
        uses: digitalocean/app_action@main
        with:
          app_name: myapp
          token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
```

---

## Logs

### Via UI
App → **Runtime Logs**

### Via CLI
```bash
doctl apps logs APP_ID --type run
doctl apps logs APP_ID --type build
doctl apps logs APP_ID -f  # Follow
```

---

## Jobs (Cron)

```yaml
# app.yaml
jobs:
  - name: cleanup
    kind: PRE_DEPLOY  # or POST_DEPLOY, FAILED_DEPLOY
    dockerfile_path: Dockerfile.job
    github:
      repo: username/myapp
      branch: main

  - name: scheduled-task
    kind: SCHEDULED
    cron: "0 2 * * *"  # Daily at 2 AM
    dockerfile_path: Dockerfile.cron
```

---

## Workers

```yaml
# app.yaml
workers:
  - name: background-worker
    dockerfile_path: Dockerfile.worker
    github:
      repo: username/myapp
      branch: main
    instance_count: 1
    instance_size_slug: basic-xxs
    envs:
      - key: QUEUE_URL
        value: ${redis.REDIS_URL}
```

---

## Static Sites (Free)

```yaml
# app.yaml
static_sites:
  - name: frontend
    github:
      repo: username/frontend
      branch: main
    build_command: npm run build
    output_dir: dist
    routes:
      - path: /
```

---

## Troubleshooting

### Build fails

```bash
# Check build logs
doctl apps logs APP_ID --type build
```

### App crashes

```bash
# Check runtime logs
doctl apps logs APP_ID --type run -f
```

### Deployment stuck

1. Check **Activity** tab
2. Cancel and redeploy
3. Check resource limits

---

## Quick Commands

```bash
# === AUTH ===
doctl auth init

# === APPS ===
doctl apps list
doctl apps get APP_ID
doctl apps create --spec app.yaml
doctl apps update APP_ID --spec app.yaml
doctl apps delete APP_ID

# === DEPLOY ===
doctl apps create-deployment APP_ID

# === LOGS ===
doctl apps logs APP_ID
doctl apps logs APP_ID -f

# === SPEC ===
doctl apps spec get APP_ID > app.yaml
```
