# VPS Manual Deployment

> Deploy Docker container lên VPS với full control. Phù hợp cho người muốn hiểu chi tiết process.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Type** | Self-managed |
| **Cost** | $5-20/month (VPS) |
| **Difficulty** | Trung bình |
| **Best for** | Learning, small projects, full control |

---

## VPS Providers

| Provider | Cheapest Plan | Notes |
|----------|---------------|-------|
| **DigitalOcean** | $4/month | Simple, good docs |
| **Vultr** | $2.50/month | Cheap, many regions |
| **Linode** | $5/month | Good performance |
| **Hetzner** | €3.29/month | Best value in EU |
| **AWS Lightsail** | $3.50/month | AWS ecosystem |

---

## Initial Server Setup

### 1. Connect to VPS

```bash
ssh root@YOUR_SERVER_IP

# Hoặc với key
ssh -i ~/.ssh/mykey root@YOUR_SERVER_IP
```

### 2. Create non-root user

```bash
# Create user
adduser deploy
usermod -aG sudo deploy

# Setup SSH key
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Test login
ssh deploy@YOUR_SERVER_IP
```

### 3. Basic security

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y ufw fail2ban

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable

# Disable root SSH login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

---

## Install Docker

### Ubuntu/Debian

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker deploy

# Verify
docker --version
docker compose version
```

### CentOS/RHEL

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

---

## Deploy Application

### Method 1: Pull from Registry

```bash
# Login to registry (if private)
docker login ghcr.io -u USERNAME -p TOKEN

# Pull image
docker pull ghcr.io/username/myapp:latest

# Run container
docker run -d \
  --name myapp \
  --restart unless-stopped \
  -p 3000:3000 \
  -e DATABASE_URL="$DATABASE_URL" \
  -e NODE_ENV=production \
  ghcr.io/username/myapp:latest
```

### Method 2: Build on Server

```bash
# Clone repo
git clone https://github.com/username/myapp.git
cd myapp

# Build image
docker build -t myapp:latest .

# Run
docker run -d \
  --name myapp \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env.production \
  myapp:latest
```

---

## Useful Commands

```bash
# View running containers
docker ps

# View logs
docker logs myapp
docker logs -f myapp  # Follow

# Restart container
docker restart myapp

# Stop container
docker stop myapp

# Remove container
docker rm myapp

# Update container
docker pull ghcr.io/username/myapp:latest
docker stop myapp
docker rm myapp
docker run -d --name myapp ... ghcr.io/username/myapp:latest
```

---

## Setup Nginx Reverse Proxy

### Install Nginx

```bash
sudo apt install -y nginx
```

### Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/myapp
```

```nginx
server {
    listen 80;
    server_name myapp.com www.myapp.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

---

## Setup SSL with Certbot

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d myapp.com -d www.myapp.com

# Auto-renewal (already configured)
sudo certbot renew --dry-run
```

---

## Health Monitoring

### Simple health check script

```bash
#!/bin/bash
# /home/deploy/check-health.sh

CONTAINER="myapp"
HEALTH_URL="http://localhost:3000/health"

if ! docker ps | grep -q $CONTAINER; then
    echo "Container $CONTAINER is not running!"
    docker start $CONTAINER
    exit 1
fi

if ! curl -sf $HEALTH_URL > /dev/null; then
    echo "Health check failed!"
    docker restart $CONTAINER
    exit 1
fi

echo "OK"
```

### Setup cron job

```bash
chmod +x /home/deploy/check-health.sh

# Run every 5 minutes
crontab -e
*/5 * * * * /home/deploy/check-health.sh >> /home/deploy/health.log 2>&1
```

---

## Auto-restart on Reboot

Docker's `--restart unless-stopped` flag handles this, but verify:

```bash
sudo systemctl enable docker
```

---

## Update Deployment Script

```bash
#!/bin/bash
# /home/deploy/update.sh

set -e

IMAGE="ghcr.io/username/myapp:latest"
CONTAINER="myapp"

echo "Pulling latest image..."
docker pull $IMAGE

echo "Stopping old container..."
docker stop $CONTAINER || true
docker rm $CONTAINER || true

echo "Starting new container..."
docker run -d \
  --name $CONTAINER \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file /home/deploy/.env.production \
  $IMAGE

echo "Cleaning up old images..."
docker image prune -f

echo "Done!"
```

---

## Troubleshooting

### Container keeps restarting

```bash
# Check logs
docker logs myapp

# Check exit code
docker inspect myapp --format='{{.State.ExitCode}}'
```

### Port already in use

```bash
# Find process using port
sudo lsof -i :3000
sudo netstat -tulpn | grep 3000

# Kill process
sudo kill -9 PID
```

### Out of disk space

```bash
# Check disk
df -h

# Clean up Docker
docker system prune -a
docker volume prune
```

---

## Security Checklist

- [ ] Non-root user created
- [ ] SSH key authentication only
- [ ] Root SSH login disabled
- [ ] Firewall configured (UFW)
- [ ] Fail2ban installed
- [ ] Docker containers run as non-root
- [ ] Secrets in environment variables, not in image
- [ ] SSL/HTTPS enabled
- [ ] Regular security updates
