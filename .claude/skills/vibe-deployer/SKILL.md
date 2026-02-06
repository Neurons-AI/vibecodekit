---
name: vibe-deployer
description: DevOps agent with complete Docker deployment skill - Build, Push, Deploy to any platform. Supports all major registries, cloud platforms, and CI/CD pipelines.
disable-model-invocation: true
argument-hint: "[action] - Options: build, push, deploy, ci-cd, full"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(docker:*), Bash(docker-compose:*)
---

# Docker Deploy Skill

Complete Docker deployment solution cho bất kỳ project nào. Hỗ trợ tất cả registries, platforms và CI/CD pipelines phổ biến.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       DOCKER DEPLOY WORKFLOW                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│   │  BUILD   │ -> │   PUSH   │ -> │  DEPLOY  │ -> │ RUNNING  │         │
│   │  Image   │    │ Registry │    │ Platform │    │   App    │         │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘         │
│        │               │               │                                 │
│        v               v               v                                 │
│   templates/      registries/     platforms/                            │
│                                                                          │
│   + CI/CD Automation ──────────────────────────> ci-cd/                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Supported Technologies

### Project Types (Dockerfile Templates)
| Category | Technologies |
|----------|-------------|
| **JavaScript/TypeScript** | Next.js, Node.js, Express, NestJS, Fastify |
| **Python** | FastAPI, Flask, Django, Streamlit |
| **Go** | Gin, Echo, Fiber, Chi, standard library |
| **PHP** | Laravel, Symfony, WordPress |
| **Java** | Spring Boot, Quarkus, Micronaut |
| **.NET** | ASP.NET Core, Blazor |
| **Rust** | Actix-web, Axum, Rocket |
| **Static** | HTML/CSS/JS, React, Vue, Angular |

### Container Registries
| Registry | Guide |
|----------|-------|
| Docker Hub | [registries/docker-hub.md](registries/docker-hub.md) |
| GitHub Container Registry | [registries/github-ghcr.md](registries/github-ghcr.md) |
| GitLab Container Registry | [registries/gitlab-registry.md](registries/gitlab-registry.md) |
| AWS ECR | [registries/aws-ecr.md](registries/aws-ecr.md) |
| Google Artifact Registry | [registries/google-gar.md](registries/google-gar.md) |
| Azure Container Registry | [registries/azure-acr.md](registries/azure-acr.md) |

### Deployment Platforms
| Platform | Type | Guide |
|----------|------|-------|
| VPS (Manual) | Self-managed | [platforms/vps-manual.md](platforms/vps-manual.md) |
| VPS (Docker Compose) | Self-managed | [platforms/vps-docker-compose.md](platforms/vps-docker-compose.md) |
| Railway | PaaS | [platforms/railway.md](platforms/railway.md) |
| Render | PaaS | [platforms/render.md](platforms/render.md) |
| Fly.io | PaaS | [platforms/fly-io.md](platforms/fly-io.md) |
| DigitalOcean App Platform | PaaS | [platforms/digitalocean-app.md](platforms/digitalocean-app.md) |
| AWS ECS | Cloud | [platforms/aws-ecs.md](platforms/aws-ecs.md) |
| AWS Lightsail | Cloud | [platforms/aws-lightsail.md](platforms/aws-lightsail.md) |
| Google Cloud Run | Cloud | [platforms/google-cloud-run.md](platforms/google-cloud-run.md) |
| Azure Container Apps | Cloud | [platforms/azure-container-apps.md](platforms/azure-container-apps.md) |
| Coolify | Self-hosted PaaS | [platforms/coolify.md](platforms/coolify.md) |

### CI/CD Pipelines
| Provider | Guide |
|----------|-------|
| GitHub Actions | [ci-cd/github-actions.md](ci-cd/github-actions.md) |
| GitLab CI | [ci-cd/gitlab-ci.md](ci-cd/gitlab-ci.md) |
| Bitbucket Pipelines | [ci-cd/bitbucket-pipelines.md](ci-cd/bitbucket-pipelines.md) |
| Jenkins | [ci-cd/jenkins.md](ci-cd/jenkins.md) |

---

## Workflow

### Step 1: Build Docker Image

**Detect project type** (auto hoặc specify):
```
package.json + next.config.*    → Next.js
package.json                    → Node.js
requirements.txt / pyproject.toml → Python
go.mod                          → Go
composer.json                   → PHP
pom.xml / build.gradle          → Java
*.csproj                        → .NET
Cargo.toml                      → Rust
index.html (no backend)         → Static
```

**Generate files:**
1. `Dockerfile` - Multi-stage build, optimized
2. `docker-compose.yml` - Development config
3. `docker-compose.prod.yml` - Production config
4. `.dockerignore` - Exclude unnecessary files

**Templates:** See [templates/](templates/) folder

---

### Step 2: Choose Container Registry

Hỏi user muốn push image lên registry nào:

| Registry | Best For | Cost |
|----------|----------|------|
| **Docker Hub** | Public images, beginners | 1 free private repo |
| **GitHub GHCR** | GitHub projects | Free unlimited private |
| **GitLab Registry** | GitLab projects | Free unlimited |
| **AWS ECR** | AWS deployments | 500MB free tier |
| **Google GAR** | GCP deployments | Free tier available |
| **Azure ACR** | Azure deployments | Paid |

**Guides:** See [registries/](registries/) folder

---

### Step 3: Choose Deployment Platform

Hỏi user muốn deploy lên platform nào:

| If user wants... | Recommend |
|------------------|-----------|
| Free, easy, learning | Railway, Render |
| Full control, cheap | VPS + Docker Compose |
| Self-hosted PaaS | Coolify |
| Enterprise/Scale | AWS ECS, Google Cloud Run |
| Edge deployment | Fly.io |

**Guides:** See [platforms/](platforms/) folder

---

### Step 4: Setup CI/CD (Optional)

Hỏi user có muốn setup CI/CD không:

| If using... | Recommend |
|-------------|-----------|
| GitHub | GitHub Actions |
| GitLab | GitLab CI |
| Bitbucket | Bitbucket Pipelines |
| Self-hosted | Jenkins |

**Templates:** See [ci-cd/](ci-cd/) folder

---

## Quick Reference

### Common Commands

```bash
# === BUILD ===
docker build -t myapp:latest .
docker build -t myapp:v1.0.0 --no-cache .

# === TAG ===
docker tag myapp:latest registry/username/myapp:latest

# === PUSH ===
docker push registry/username/myapp:latest

# === RUN LOCAL ===
docker-compose up -d
docker-compose -f docker-compose.prod.yml up -d

# === DEPLOY ===
# (varies by platform - see platform guides)
```

### Environment Variables

```bash
# Build-time (in Dockerfile)
ARG NODE_ENV=production

# Runtime (in docker-compose or platform)
environment:
  - DATABASE_URL=${DATABASE_URL}
  - API_KEY=${API_KEY}
```

---

## Important Rules

### MUST DO:
- [ ] Multi-stage build để giảm image size
- [ ] Non-root user trong container
- [ ] `.dockerignore` để exclude files
- [ ] HEALTHCHECK cho monitoring
- [ ] Pin version base images
- [ ] Secrets qua environment variables, KHÔNG hardcode

### MUST NOT:
- [ ] KHÔNG copy `.env` files vào image
- [ ] KHÔNG dùng `latest` tag cho production
- [ ] KHÔNG chạy container với root user
- [ ] KHÔNG expose database ports publicly
- [ ] KHÔNG commit secrets vào git

---

## Recommended Combinations

### For Students/Learning
```
Build → GitHub GHCR → Railway/Render → GitHub Actions
(Free, easy to setup, good documentation)
```

### For Startups
```
Build → AWS ECR → AWS ECS/Fargate → GitHub Actions
(Scalable, professional, pay-as-you-go)
```

### For Self-hosters
```
Build → Docker Hub → VPS + Coolify → GitLab CI
(Full control, one-time cost VPS)
```

### For Enterprise
```
Build → Private Registry → Kubernetes → Jenkins/ArgoCD
(Maximum control and scale)
```

---

## File Structure

```
.claude/skills/docker-deploy/
├── SKILL.md                    # This file
├── README.md                   # User guide
├── checklist.md                # Security checklist
│
├── templates/                  # Dockerfile templates
│   ├── nextjs.Dockerfile
│   ├── node.Dockerfile
│   ├── python.Dockerfile
│   ├── go.Dockerfile
│   ├── php.Dockerfile
│   ├── java.Dockerfile
│   ├── dotnet.Dockerfile
│   ├── rust.Dockerfile
│   ├── static.Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose.prod.yml
│   ├── dockerignore.txt
│   └── entrypoint.sh
│
├── registries/                 # Container registry guides
│   ├── docker-hub.md
│   ├── github-ghcr.md
│   ├── gitlab-registry.md
│   ├── aws-ecr.md
│   ├── google-gar.md
│   └── azure-acr.md
│
├── platforms/                  # Deployment platform guides
│   ├── vps-manual.md
│   ├── vps-docker-compose.md
│   ├── railway.md
│   ├── render.md
│   ├── fly-io.md
│   ├── digitalocean-app.md
│   ├── aws-ecs.md
│   ├── aws-lightsail.md
│   ├── google-cloud-run.md
│   ├── azure-container-apps.md
│   └── coolify.md
│
└── ci-cd/                      # CI/CD pipeline templates
    ├── github-actions.md
    ├── gitlab-ci.md
    ├── bitbucket-pipelines.md
    └── jenkins.md
```

---

## Troubleshooting

See [checklist.md](checklist.md) for common issues and solutions.

---

## Version History

- **v2.0.0** - Added registries, platforms, CI/CD guides
- **v1.0.0** - Initial release with Dockerfile templates
