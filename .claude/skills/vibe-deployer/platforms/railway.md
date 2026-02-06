# Railway

> Platform-as-a-Service dễ dùng, deploy từ GitHub hoặc Docker image. Có free tier.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://railway.app |
| **Free tier** | $5 credit/month |
| **Difficulty** | Rất dễ |
| **Best for** | Beginners, side projects, quick deploys |

---

## Pricing

| Plan | Price | Resources |
|------|-------|-----------|
| **Hobby** | $5 credit/month | Enough for small apps |
| **Pro** | $20/month | More resources, team features |

---

## Deploy Methods

### Method 1: From GitHub (Recommended)

1. Go to https://railway.app
2. Click **Start a New Project**
3. Select **Deploy from GitHub repo**
4. Authorize GitHub access
5. Select repository
6. Railway auto-detects Dockerfile
7. Click **Deploy**

### Method 2: From Docker Image

1. **New Project** → **Deploy from Docker Image**
2. Enter image URL: `ghcr.io/username/myapp:latest`
3. Add registry credentials if private
4. Configure environment variables
5. Deploy

### Method 3: Railway CLI

```bash
# Install CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Deploy
railway up
```

---

## Configuration

### railway.toml (Optional)

```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 3
```

### Environment Variables

1. Go to project → **Variables**
2. Add variables:
   ```
   NODE_ENV=production
   DATABASE_URL=postgresql://...
   SECRET_KEY=your-secret
   ```

> **Tip:** Use **Raw Editor** để paste nhiều variables cùng lúc

---

## Database Setup

### Add PostgreSQL

1. Project → **+ New** → **Database** → **PostgreSQL**
2. Copy `DATABASE_URL` from database variables
3. Add to your service's variables

### Add Redis

1. Project → **+ New** → **Database** → **Redis**
2. Copy `REDIS_URL`

---

## Custom Domain

1. Project → Service → **Settings**
2. **Networking** → **Generate Domain** (railway subdomain)
3. Or **Custom Domain** → Add your domain
4. Update DNS:
   ```
   Type: CNAME
   Name: @ or subdomain
   Value: <your-app>.up.railway.app
   ```

---

## Dockerfile for Railway

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup -S nodejs && adduser -S nodejs -G nodejs
USER nodejs

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Railway sets PORT automatically
EXPOSE ${PORT:-3000}

CMD ["node", "dist/index.js"]
```

> **Important:** Railway sets `PORT` environment variable automatically. Use it!

---

## Health Checks

Railway supports health checks:

```toml
# railway.toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 100
```

Or in service settings → **Deploy** → **Health Check Path**

---

## Logs & Monitoring

### View Logs

- Dashboard → Service → **Logs** tab
- Or CLI: `railway logs`

### Metrics

- Dashboard → Service → **Metrics** tab
- CPU, Memory, Network usage

---

## Scaling

### Vertical Scaling

- Settings → **Resources**
- Adjust vCPU and Memory

### Horizontal Scaling (Pro plan)

- Settings → **Replicas**
- Increase replica count

---

## CI/CD with GitHub Actions

Railway auto-deploys on push, but you can customize:

```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Railway CLI
        run: npm install -g @railway/cli

      - name: Deploy
        run: railway up
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

### Get Railway Token

1. Account → **Tokens** → **Create Token**
2. Add to GitHub secrets as `RAILWAY_TOKEN`

---

## Private Docker Registry

1. Service → **Settings** → **Source**
2. Select **Docker Image**
3. Enter image URL
4. Add **Registry Credentials**:
   - Username
   - Password/Token

---

## Monorepo Support

```toml
# railway.toml
[build]
builder = "dockerfile"
dockerfilePath = "apps/backend/Dockerfile"
watchPatterns = ["apps/backend/**"]
```

---

## Common Issues

### Port binding error

```dockerfile
# Sử dụng PORT từ environment
EXPOSE ${PORT:-3000}
CMD ["sh", "-c", "node server.js --port $PORT"]
```

### Build fails

- Check **Build Logs** in dashboard
- Ensure Dockerfile builds locally first
- Check memory limits (may need Pro plan)

### Database connection refused

- Use internal URL from Railway (not external)
- Check DATABASE_URL format

---

## Quick Reference

```bash
# === CLI ===
railway login         # Login
railway init          # Init project
railway up            # Deploy
railway logs          # View logs
railway run <cmd>     # Run command in production env

# === Variables ===
railway variables     # List variables
railway variables set KEY=value

# === Domains ===
railway domain        # Get/set domain
```

---

## Comparison with Alternatives

| Feature | Railway | Render | Fly.io |
|---------|---------|--------|--------|
| Free tier | $5/month | Free (limited) | Free (limited) |
| Ease of use | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Docker support | ✅ | ✅ | ✅ |
| Database | ✅ | ✅ | ✅ |
| Auto-deploy | ✅ | ✅ | ✅ |
| Custom domain | ✅ | ✅ | ✅ |
