# Fly.io

> Deploy Docker containers globally, close to users. Edge deployment made easy.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://fly.io |
| **Free tier** | 3 shared VMs, 3GB storage |
| **Difficulty** | Trung bình |
| **Best for** | Global apps, low latency, edge deployment |

---

## Pricing

| Resource | Free Tier | Paid |
|----------|-----------|------|
| **VMs** | 3 shared-cpu-1x | $1.94/month (shared) |
| **Storage** | 3GB | $0.15/GB/month |
| **Bandwidth** | 100GB | $0.02/GB |

---

## Install flyctl CLI

```bash
# macOS
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

### Login

```bash
fly auth login
```

---

## Deploy Methods

### Method 1: From Dockerfile (Recommended)

```bash
# Navigate to project
cd myapp

# Launch (first time)
fly launch

# Deploy (subsequent)
fly deploy
```

### Method 2: From Docker Image

```bash
fly launch --image ghcr.io/username/myapp:latest
```

---

## Configuration

### fly.toml

```toml
app = "myapp"
primary_region = "sin"  # Singapore

[build]
  dockerfile = "Dockerfile"

[env]
  NODE_ENV = "production"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "connections"
    hard_limit = 25
    soft_limit = 20

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 512
```

### Secrets (Environment Variables)

```bash
# Set secret
fly secrets set DATABASE_URL="postgresql://..."
fly secrets set SECRET_KEY="mysecret"

# List secrets
fly secrets list

# Unset
fly secrets unset SECRET_KEY
```

---

## Database Setup

### Fly Postgres

```bash
# Create Postgres cluster
fly postgres create --name myapp-db

# Attach to app
fly postgres attach myapp-db

# Connect via proxy
fly proxy 5432 -a myapp-db
```

### External Database

Just set `DATABASE_URL` as a secret:

```bash
fly secrets set DATABASE_URL="postgresql://user:pass@host:5432/db?sslmode=require"
```

---

## Regions

### Deploy to multiple regions

```bash
# Add region
fly scale count 2 --region sin,nrt  # Singapore + Tokyo

# List regions
fly regions list
```

### Available Regions

| Code | Location |
|------|----------|
| sin | Singapore |
| nrt | Tokyo |
| hkg | Hong Kong |
| syd | Sydney |
| iad | Virginia (US) |
| lax | Los Angeles |
| ams | Amsterdam |
| lhr | London |
| fra | Frankfurt |

---

## Custom Domain

```bash
# Add custom domain
fly certs add myapp.com

# Check status
fly certs show myapp.com
```

Update DNS:
```
Type: CNAME
Name: @
Value: myapp.fly.dev
```

Or for apex domain:
```
Type: A
Name: @
Value: <fly-app-ip>  # Get from fly ips list
```

---

## Scaling

### Vertical

```bash
# Scale up memory/CPU
fly scale vm shared-cpu-2x
fly scale memory 1024
```

### Horizontal

```bash
# Scale replicas
fly scale count 3

# Per region
fly scale count 2 --region sin
fly scale count 1 --region nrt
```

### Auto-scaling

```toml
# fly.toml
[http_service]
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1
```

---

## Volumes (Persistent Storage)

```bash
# Create volume
fly volumes create myapp_data --size 1 --region sin

# List volumes
fly volumes list
```

```toml
# fly.toml
[mounts]
  source = "myapp_data"
  destination = "/app/data"
```

---

## Health Checks

```toml
# fly.toml
[http_service]
  internal_port = 3000

  [[http_service.checks]]
    interval = "15s"
    timeout = "2s"
    grace_period = "5s"
    method = "GET"
    path = "/health"
```

---

## Logs & Monitoring

```bash
# View logs
fly logs

# Follow logs
fly logs -f

# Specific instance
fly logs -i <instance-id>
```

### Monitoring Dashboard

```bash
fly dashboard
```

---

## CI/CD with GitHub Actions

```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Get API Token

```bash
fly tokens create deploy -x 999999h
# Add to GitHub secrets as FLY_API_TOKEN
```

---

## SSH Access

```bash
# SSH into running machine
fly ssh console

# Run command
fly ssh console -C "ls -la"
```

---

## Private Networking

Fly apps can communicate internally:

```bash
# From app A to app B
curl http://app-b.internal:3000/api
```

```toml
# fly.toml
[env]
  OTHER_SERVICE_URL = "http://other-app.internal:3000"
```

---

## Dockerfile for Fly.io

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

RUN addgroup -S nodejs && adduser -S nodejs -G nodejs
USER nodejs

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

---

## Common Commands

```bash
# === DEPLOYMENT ===
fly launch           # First time setup
fly deploy           # Deploy changes
fly deploy --local-only  # Build locally then deploy

# === STATUS ===
fly status           # App status
fly apps list        # List all apps
fly machines list    # List machines

# === LOGS ===
fly logs             # View logs
fly logs -f          # Follow logs

# === SCALING ===
fly scale count 2    # Scale to 2 instances
fly scale vm shared-cpu-2x  # Upgrade VM

# === SECRETS ===
fly secrets set KEY=value
fly secrets list
fly secrets unset KEY

# === SSH ===
fly ssh console      # SSH into machine

# === DATABASE ===
fly postgres create  # Create Postgres
fly postgres attach  # Attach to app
```

---

## Troubleshooting

### App not starting

```bash
# Check logs
fly logs

# Check health
fly status

# SSH and debug
fly ssh console
```

### Out of memory

```bash
# Increase memory
fly scale memory 1024
```

### Connection refused

- Check `internal_port` in fly.toml matches your app
- Ensure app listens on `0.0.0.0`, not `localhost`

---

## Comparison

| Feature | Fly.io | Railway | Render |
|---------|--------|---------|--------|
| Global regions | ✅ (30+) | ❌ (few) | ❌ (few) |
| Edge deployment | ✅ | ❌ | ❌ |
| Free tier | ✅ | ✅ | ✅ |
| Docker | ✅ | ✅ | ✅ |
| Postgres | ✅ | ✅ | ✅ |
| Ease of use | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
