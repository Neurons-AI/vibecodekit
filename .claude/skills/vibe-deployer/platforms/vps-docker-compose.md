# VPS with Docker Compose

> Deploy với Docker Compose trên VPS. Dễ quản lý multiple services và configs.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Type** | Self-managed |
| **Cost** | $5-20/month |
| **Difficulty** | Dễ - Trung bình |
| **Best for** | Multi-service apps, easier updates |

---

## Prerequisites

1. VPS với Docker installed (xem [vps-manual.md](vps-manual.md))
2. Docker Compose installed
3. Domain pointing to VPS IP

---

## Project Structure

```
/home/deploy/myapp/
├── docker-compose.yml      # Production compose
├── .env                    # Environment variables
├── nginx/
│   └── nginx.conf         # Nginx config
├── data/                   # Persistent data
│   ├── postgres/
│   └── uploads/
└── backups/               # Database backups
```

---

## Docker Compose Production Config

### docker-compose.yml

```yaml
services:
  app:
    image: ghcr.io/username/myapp:latest
    restart: always
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@postgres:5432/myapp
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - internal
      - web
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  postgres:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:1.25-alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
      - ./data/certbot:/var/www/certbot:ro
    depends_on:
      - app
    networks:
      - web

  # Optional: Redis for caching/sessions
  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - ./data/redis:/data
    networks:
      - internal

networks:
  internal:
    driver: bridge
  web:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

### .env file

```bash
# Database
DB_USER=myapp
DB_PASSWORD=super_secret_password_here
DB_NAME=myapp

# App
NODE_ENV=production
SECRET_KEY=your_secret_key_here

# Registry (for pulling images)
REGISTRY_USER=username
REGISTRY_TOKEN=ghp_xxxx
```

---

## Nginx Configuration

### nginx/nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    # Upstream
    upstream app {
        server app:3000;
    }

    # HTTP -> HTTPS redirect
    server {
        listen 80;
        server_name myapp.com www.myapp.com;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS
    server {
        listen 443 ssl http2;
        server_name myapp.com www.myapp.com;

        ssl_certificate /etc/nginx/certs/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/privkey.pem;

        # SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        location / {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;

            # Rate limiting for API
            location /api/ {
                limit_req zone=api burst=20 nodelay;
                proxy_pass http://app;
            }
        }
    }
}
```

---

## Deployment Commands

### Initial Deploy

```bash
# SSH to server
ssh deploy@YOUR_SERVER_IP

# Create directory
mkdir -p ~/myapp
cd ~/myapp

# Copy files (from local)
scp docker-compose.yml deploy@SERVER:~/myapp/
scp -r nginx deploy@SERVER:~/myapp/
scp .env.production deploy@SERVER:~/myapp/.env

# Or clone from repo
git clone https://github.com/username/myapp-deploy.git .

# Login to registry
echo $REGISTRY_TOKEN | docker login ghcr.io -u $REGISTRY_USER --password-stdin

# Pull images
docker compose pull

# Start services
docker compose up -d

# Check status
docker compose ps
docker compose logs -f
```

### Update Deployment

```bash
#!/bin/bash
# update.sh

cd ~/myapp

# Pull latest images
docker compose pull

# Restart services (zero-downtime for stateless apps)
docker compose up -d --remove-orphans

# Clean up
docker image prune -f

echo "Updated successfully!"
```

---

## SSL Setup with Certbot

### Method 1: Standalone (simple)

```bash
# Stop nginx temporarily
docker compose stop nginx

# Get certificate
sudo certbot certonly --standalone -d myapp.com -d www.myapp.com

# Copy certs
sudo cp /etc/letsencrypt/live/myapp.com/fullchain.pem ~/myapp/certs/
sudo cp /etc/letsencrypt/live/myapp.com/privkey.pem ~/myapp/certs/
sudo chown deploy:deploy ~/myapp/certs/*

# Start nginx
docker compose start nginx
```

### Method 2: Certbot container

```yaml
# Add to docker-compose.yml
certbot:
  image: certbot/certbot
  volumes:
    - ./data/certbot:/var/www/certbot
    - ./certs:/etc/letsencrypt
  command: certonly --webroot -w /var/www/certbot --email you@email.com -d myapp.com --agree-tos
```

---

## Backup Strategy

### Database backup script

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR=~/myapp/backups
DATE=$(date +%Y%m%d_%H%M%S)

# Backup PostgreSQL
docker compose exec -T postgres pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/db_$DATE.sql

# Compress
gzip $BACKUP_DIR/db_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: db_$DATE.sql.gz"
```

### Cron job

```bash
# Run daily at 2 AM
crontab -e
0 2 * * * /home/deploy/myapp/backup.sh >> /home/deploy/myapp/backups/backup.log 2>&1
```

---

## Monitoring

### Simple monitoring with healthchecks.io

```bash
#!/bin/bash
# monitor.sh

HEALTHCHECK_URL="https://hc-ping.com/your-uuid"

cd ~/myapp

# Check if services are running
if docker compose ps | grep -q "unhealthy\|Exit"; then
    curl -fsS --retry 3 $HEALTHCHECK_URL/fail
    exit 1
fi

# Ping success
curl -fsS --retry 3 $HEALTHCHECK_URL
```

### Logs management

```yaml
# Add to each service in docker-compose.yml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

---

## Rollback

```bash
# Keep previous image tag
docker tag ghcr.io/username/myapp:latest ghcr.io/username/myapp:previous

# If need rollback
docker compose down
# Edit docker-compose.yml to use :previous tag
docker compose up -d
```

---

## Troubleshooting

### View logs

```bash
# All services
docker compose logs

# Specific service
docker compose logs app
docker compose logs -f app  # Follow
```

### Enter container

```bash
docker compose exec app sh
docker compose exec postgres psql -U myapp
```

### Restart services

```bash
docker compose restart
docker compose restart app
```

### Check resource usage

```bash
docker stats
```

---

## Quick Commands Reference

```bash
# === DEPLOYMENT ===
docker compose up -d              # Start all
docker compose down               # Stop all
docker compose restart            # Restart all
docker compose pull               # Pull latest images

# === LOGS ===
docker compose logs -f            # Follow all logs
docker compose logs -f app        # Follow app logs

# === MAINTENANCE ===
docker compose exec app sh        # Shell into app
docker compose exec postgres psql -U user dbname  # DB shell

# === CLEANUP ===
docker system prune -f            # Clean unused
docker volume prune -f            # Clean volumes
```
