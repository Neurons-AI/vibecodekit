# Coolify

> Self-hosted PaaS alternative to Heroku/Vercel. Deploy trên VPS của bạn.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://coolify.io |
| **Cost** | Free (self-hosted) hoặc Cloud từ $5/month |
| **Difficulty** | Dễ (sau khi setup) |
| **Best for** | Self-hosting, full control, privacy |

---

## What is Coolify?

Coolify là open-source PaaS bạn có thể self-host:
- Deploy từ GitHub/GitLab
- Auto SSL với Let's Encrypt
- Database management
- Auto backups
- Team collaboration
- Monitoring & logs

---

## Installation

### Requirements

- VPS với 2GB RAM minimum
- Ubuntu 22.04+ hoặc Debian 12+
- Domain pointing to VPS

### One-line Install

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

### Access Dashboard

1. Open `http://YOUR_SERVER_IP:8000`
2. Create admin account
3. Setup complete!

---

## Initial Configuration

### 1. Add Server

Dashboard → **Servers** → **Add Server**

For localhost (same server):
- **Server Type:** Localhost
- Click **Validate**

### 2. Add Destination

Destinations are Docker networks:
- Dashboard → **Destinations**
- Usually auto-created

### 3. Connect Git Provider

Settings → **Git Providers**
- GitHub: Create OAuth app
- GitLab: Create OAuth app
- Or use Deploy Keys

---

## Deploy Application

### From GitHub

1. **Projects** → **New Project**
2. **Add Resource** → **Application**
3. Select **GitHub**
4. Choose repository
5. Configure:
   - Build Pack: **Dockerfile** or **Nixpacks**
   - Port: `3000`
   - Domain: `myapp.yourdomain.com`
6. **Deploy**

### From Docker Image

1. **Add Resource** → **Application**
2. Select **Docker Image**
3. Enter image: `ghcr.io/username/myapp:latest`
4. Add registry credentials if private
5. Configure port and domain
6. **Deploy**

### From Docker Compose

1. **Add Resource** → **Docker Compose**
2. Paste your `docker-compose.yml`
3. Or link to repo containing compose file
4. **Deploy**

---

## Configuration

### Environment Variables

Application → **Environment Variables**

```env
NODE_ENV=production
DATABASE_URL=postgresql://...
SECRET_KEY=mysecret
```

### Persistent Storage

Application → **Storages**

```yaml
# Volume mapping
/app/data -> /var/lib/coolify/applications/xxx/data
```

### Health Checks

Application → **Health Checks**
- Path: `/health`
- Interval: 30 seconds
- Timeout: 5 seconds

---

## Database Setup

### Add Database

1. Project → **Add Resource** → **Database**
2. Select type:
   - PostgreSQL
   - MySQL
   - MariaDB
   - MongoDB
   - Redis
3. Configure and create

### Connect to App

Copy connection string from database page:
```
postgresql://user:password@INTERNAL_HOST:5432/dbname
```

Add to app's environment variables.

---

## Domain & SSL

### Custom Domain

1. Application → **Domains**
2. Add domain: `myapp.yourdomain.com`
3. Update DNS:
   ```
   Type: A
   Name: myapp
   Value: YOUR_SERVER_IP
   ```

### SSL (Auto)

Coolify auto-provisions Let's Encrypt certificates.

### Wildcard Domain

Settings → **Wildcard Domain**
- Set: `*.yourdomain.com`
- All apps get subdomains automatically

---

## Auto Deploy

### Webhook (Push to Deploy)

Application → **Webhooks**
- Copy webhook URL
- Add to GitHub repo settings

### Scheduled Builds

Application → **Scheduled Tasks**
- Cron: `0 2 * * *` (Daily 2 AM)

---

## Docker Compose Example

```yaml
# coolify-compose.yml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - postgres
    labels:
      - "coolify.managed=true"

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

## Backups

### Database Backups

Database → **Backups**
- Schedule: Daily
- Retention: 7 days
- Storage: Local or S3

### S3 Backup Storage

Settings → **S3 Storages**
- Add S3 credentials
- Use for backups

---

## Monitoring

### Built-in Metrics

Dashboard shows:
- CPU usage
- Memory usage
- Network I/O
- Disk usage

### Logs

Application → **Logs**
- Build logs
- Application logs
- Real-time streaming

---

## Team Management

Settings → **Teams**
- Create teams
- Invite members
- Set permissions

---

## CLI (coolctl)

```bash
# Install
curl -fsSL https://cdn.coollabs.io/coolify/coolctl/install.sh | bash

# Login
coolctl login

# Deploy
coolctl deploy --project myproject --app myapp

# Logs
coolctl logs --app myapp

# Status
coolctl status --app myapp
```

---

## Comparison with Others

| Feature | Coolify | Railway | Render | Heroku |
|---------|---------|---------|--------|--------|
| Self-hosted | ✅ | ❌ | ❌ | ❌ |
| Cost | Free* | $5+/month | Free+ | $7+/month |
| Docker Compose | ✅ | ❌ | ❌ | ❌ |
| Managed DB | ✅ | ✅ | ✅ | ✅ |
| Auto SSL | ✅ | ✅ | ✅ | ✅ |
| Private networking | ✅ | ✅ | ✅ | ✅ |

*Free = only VPS cost

---

## Troubleshooting

### Build fails

1. Check **Build Logs**
2. Verify Dockerfile works locally
3. Check resource limits (RAM)

### App not accessible

1. Check **Application Logs**
2. Verify port configuration
3. Check domain DNS

### Database connection failed

1. Use internal hostname (not localhost)
2. Check credentials
3. Verify network connectivity

### SSL not working

1. Wait for DNS propagation
2. Check domain points to correct IP
3. Check Let's Encrypt rate limits

---

## Quick Start Checklist

- [ ] Install Coolify on VPS
- [ ] Configure wildcard domain
- [ ] Connect GitHub/GitLab
- [ ] Create project
- [ ] Add application
- [ ] Configure domain
- [ ] Add environment variables
- [ ] Deploy!

---

## Resources

- Documentation: https://coolify.io/docs
- GitHub: https://github.com/coollabsio/coolify
- Discord: https://discord.gg/coolify
