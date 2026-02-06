# Vibe Deployer with advanced Docker Deploy Skill

> Complete Docker deployment skill - Từ build image đến deploy lên production.

---

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Cài đặt](#cài-đặt)
- [Quick Start](#quick-start)
- [Supported Technologies](#supported-technologies)
- [Workflow](#workflow)
- [Hướng dẫn từng bước](#hướng-dẫn-từng-bước)
- [FAQ](#faq)

---

## Giới thiệu

Skill này giúp bạn deploy bất kỳ ứng dụng nào lên production với Docker:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   BUILD     │ -> │    PUSH     │ -> │   DEPLOY    │ -> │   RUNNING   │
│   Image     │    │  Registry   │    │  Platform   │    │    App      │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
     │                   │                  │
     v                   v                  v
 templates/         registries/        platforms/
```

**Có gì trong skill này:**
- 9 Dockerfile templates (Next.js, Node, Python, Go, PHP, Java, .NET, Rust, Static)
- 6 Registry guides (Docker Hub, GHCR, GitLab, AWS ECR, Google GAR, Azure ACR)
- 11 Platform guides (VPS, Railway, Render, Fly.io, AWS, GCP, Azure, Coolify...)
- 4 CI/CD templates (GitHub Actions, GitLab CI, Bitbucket, Jenkins)

---

## Cài đặt

### Copy skill vào project của bạn

```bash
# Tạo thư mục
mkdir -p .claude/skills

# Copy thư mục docker-deploy vào
cp -r path/to/docker-deploy .claude/skills/
```

### Cấu trúc thư mục

```
.claude/skills/docker-deploy/
├── SKILL.md              # Main skill documentation
├── README.md             # This file
├── checklist.md          # Security checklist
├── templates/            # Dockerfile templates
├── registries/           # Container registry guides
├── platforms/            # Deployment platform guides
└── ci-cd/                # CI/CD pipeline templates
```

---

## Quick Start

### Bước 1: Yêu cầu Claude setup Docker

```
Hãy setup Docker deployment cho project của tôi
```

### Bước 2: Claude sẽ hỏi bạn

1. **Project type?** - Next.js, Node, Python, etc.
2. **Registry nào?** - Docker Hub, GitHub, etc.
3. **Deploy lên đâu?** - Railway, VPS, AWS, etc.
4. **Cần CI/CD?** - GitHub Actions, GitLab CI, etc.

### Bước 3: Claude tạo files

```
Dockerfile
docker-compose.yml
.dockerignore
.github/workflows/deploy.yml (nếu cần CI/CD)
```

### Bước 4: Deploy!

```bash
# Local development
docker-compose up -d

# Production
docker-compose -f docker-compose.prod.yml up -d
```

---

## Supported Technologies

### Project Types

| Technology | Template | Notes |
|------------|----------|-------|
| Next.js | `nextjs.Dockerfile` | Requires `output: 'standalone'` |
| Node.js/Express | `node.Dockerfile` | Works with NestJS, Fastify |
| Python | `python.Dockerfile` | FastAPI, Flask, Django |
| Go | `go.Dockerfile` | Uses distroless |
| PHP/Laravel | `php.Dockerfile` | Includes nginx config |
| Java/Spring | `java.Dockerfile` | Maven or Gradle |
| .NET | `dotnet.Dockerfile` | ASP.NET Core |
| Rust | `rust.Dockerfile` | Multi-stage with distroless |
| Static Sites | `static.Dockerfile` | React, Vue, Angular builds |

### Container Registries

| Registry | Free Tier | Guide |
|----------|-----------|-------|
| Docker Hub | 1 private repo | [docker-hub.md](registries/docker-hub.md) |
| GitHub GHCR | Unlimited private | [github-ghcr.md](registries/github-ghcr.md) |
| GitLab Registry | Unlimited | [gitlab-registry.md](registries/gitlab-registry.md) |
| AWS ECR | 500MB | [aws-ecr.md](registries/aws-ecr.md) |
| Google GAR | 500MB | [google-gar.md](registries/google-gar.md) |
| Azure ACR | None | [azure-acr.md](registries/azure-acr.md) |

### Deployment Platforms

| Platform | Type | Cost | Guide |
|----------|------|------|-------|
| Railway | PaaS | $5/month credit | [railway.md](platforms/railway.md) |
| Render | PaaS | Free (limited) | [render.md](platforms/render.md) |
| Fly.io | PaaS | Free tier | [fly-io.md](platforms/fly-io.md) |
| VPS | Self-managed | $5-20/month | [vps-docker-compose.md](platforms/vps-docker-compose.md) |
| Coolify | Self-hosted PaaS | Free | [coolify.md](platforms/coolify.md) |
| AWS ECS | Cloud | Pay-per-use | [aws-ecs.md](platforms/aws-ecs.md) |
| Google Cloud Run | Serverless | Pay-per-request | [google-cloud-run.md](platforms/google-cloud-run.md) |
| Azure Container Apps | Serverless | Pay-per-use | [azure-container-apps.md](platforms/azure-container-apps.md) |

### CI/CD Pipelines

| Provider | Guide |
|----------|-------|
| GitHub Actions | [github-actions.md](ci-cd/github-actions.md) |
| GitLab CI | [gitlab-ci.md](ci-cd/gitlab-ci.md) |
| Bitbucket Pipelines | [bitbucket-pipelines.md](ci-cd/bitbucket-pipelines.md) |
| Jenkins | [jenkins.md](ci-cd/jenkins.md) |

---

## Workflow

### 1. Build Docker Image

```bash
# Build
docker build -t myapp:latest .

# Test locally
docker run -p 3000:3000 myapp:latest
```

### 2. Push to Registry

```bash
# Login
docker login ghcr.io -u USERNAME -p TOKEN

# Tag
docker tag myapp:latest ghcr.io/username/myapp:latest

# Push
docker push ghcr.io/username/myapp:latest
```

### 3. Deploy to Platform

**Railway:**
```bash
railway up
```

**Render:**
- Push to GitHub → Auto-deploy

**VPS:**
```bash
ssh server "cd ~/myapp && docker compose pull && docker compose up -d"
```

### 4. Setup CI/CD (Optional)

Commit `.github/workflows/deploy.yml` → Auto-deploy on push

---

## Hướng dẫn từng bước

### Scenario 1: Student project (Free)

**Recommended stack:**
- Registry: GitHub Container Registry (free unlimited)
- Platform: Railway hoặc Render (free tier)
- CI/CD: GitHub Actions (free for public repos)

**Steps:**
1. Tạo Dockerfile với template phù hợp
2. Push code lên GitHub
3. Connect Railway/Render với GitHub repo
4. Done! Auto-deploy on push

### Scenario 2: Startup/Production

**Recommended stack:**
- Registry: AWS ECR hoặc Google GAR
- Platform: AWS ECS hoặc Google Cloud Run
- CI/CD: GitHub Actions

**Steps:**
1. Setup registry (ECR/GAR)
2. Create CI/CD pipeline
3. Configure platform (ECS/Cloud Run)
4. Setup monitoring và alerting

### Scenario 3: Full control

**Recommended stack:**
- Registry: Docker Hub hoặc self-hosted
- Platform: VPS với Docker Compose hoặc Coolify
- CI/CD: GitHub Actions hoặc GitLab CI

**Steps:**
1. Setup VPS (DigitalOcean, Vultr, Hetzner)
2. Install Docker trên VPS
3. Deploy với Docker Compose
4. Setup Nginx và SSL
5. Configure CI/CD để auto-deploy

---

## FAQ

### Q: Tôi nên chọn registry nào?

**A:**
- **Beginners/Students:** GitHub GHCR (free, easy)
- **Already on GitLab:** GitLab Registry
- **AWS deployments:** AWS ECR
- **GCP deployments:** Google GAR
- **Public images:** Docker Hub

### Q: Platform nào phù hợp với tôi?

**A:**
- **Learning/Side projects:** Railway, Render (free tier)
- **Need full control:** VPS + Docker Compose
- **Self-hosted PaaS:** Coolify
- **Enterprise/Scale:** AWS ECS, Google Cloud Run
- **Global/Edge:** Fly.io

### Q: Cần CI/CD không?

**A:** Nên có! CI/CD giúp:
- Tự động test trước khi deploy
- Tự động deploy khi push code
- Rollback dễ dàng
- Consistent deployments

### Q: Image quá lớn, làm sao optimize?

**A:**
1. Dùng multi-stage build
2. Dùng Alpine base images
3. Dùng `.dockerignore`
4. Chỉ copy files cần thiết
5. Clean cache trong build

### Q: Làm sao backup database?

**A:**
```bash
# PostgreSQL
docker exec db pg_dump -U user dbname > backup.sql

# MySQL
docker exec db mysqldump -u user -p dbname > backup.sql

# SQLite
cp ./data/app.db ./backups/app_$(date +%Y%m%d).db
```

### Q: Làm sao rollback khi deploy lỗi?

**A:**
```bash
# Pull previous version
docker pull ghcr.io/username/myapp:previous-tag

# Or rollback trong platform
# Railway/Render: Chọn previous deployment
# VPS: docker compose up -d với tag cũ
```

---

## Best Practices

### Security

- [ ] KHÔNG copy `.env` vào image
- [ ] KHÔNG hardcode secrets
- [ ] Dùng non-root user trong container
- [ ] Pin version base images
- [ ] Scan images for vulnerabilities

### Performance

- [ ] Dùng multi-stage builds
- [ ] Optimize layer caching
- [ ] Dùng `.dockerignore`
- [ ] Dùng Alpine images khi có thể

### Reliability

- [ ] Thêm health checks
- [ ] Configure restart policy
- [ ] Setup logging
- [ ] Setup monitoring
- [ ] Backup strategy

---

## Resources

- [Docker Documentation](https://docs.docker.com)
- [Docker Compose Documentation](https://docs.docker.com/compose)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

---

## Support

Nếu gặp vấn đề:
1. Đọc error message
2. Check logs: `docker logs container_name`
3. Tham khảo [checklist.md](checklist.md)
4. Đọc guide của platform/registry bạn đang dùng

---

**Happy Deploying! 🚀**
