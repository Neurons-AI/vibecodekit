# GitLab Container Registry

> Registry tích hợp sẵn trong GitLab, miễn phí unlimited cho cả private repos.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | registry.gitlab.com |
| **Free tier** | Unlimited (cả private) |
| **Image format** | `registry.gitlab.com/GROUP/PROJECT:TAG` |
| **Best for** | GitLab projects, teams cần unlimited private images |

---

## Setup

### 1. Tạo Personal Access Token

1. GitLab → **User Settings** → **Access Tokens**
2. **Add new token**
3. Chọn scopes:
   - `read_registry` - Pull images
   - `write_registry` - Push images
4. Set expiration date
5. Copy và lưu token

### 2. Login

```bash
# Login với PAT
docker login registry.gitlab.com -u YOUR_GITLAB_USERNAME -p YOUR_TOKEN

# Hoặc với stdin
echo $GITLAB_TOKEN | docker login registry.gitlab.com -u YOUR_USERNAME --password-stdin
```

---

## Usage

### Image Naming

```bash
# Format cơ bản
registry.gitlab.com/GROUP/PROJECT:TAG

# Với subgroups
registry.gitlab.com/GROUP/SUBGROUP/PROJECT:TAG

# Với multiple images per project
registry.gitlab.com/GROUP/PROJECT/IMAGE_NAME:TAG

# Examples
registry.gitlab.com/mycompany/myapp:latest
registry.gitlab.com/mycompany/backend/api:v1.0.0
registry.gitlab.com/mycompany/myapp/frontend:latest
registry.gitlab.com/mycompany/myapp/backend:latest
```

### Build & Push

```bash
# Build
docker build -t myapp:latest .

# Tag
docker tag myapp:latest registry.gitlab.com/YOUR_GROUP/YOUR_PROJECT:latest

# Push
docker push registry.gitlab.com/YOUR_GROUP/YOUR_PROJECT:latest
```

### Pull

```bash
docker pull registry.gitlab.com/YOUR_GROUP/YOUR_PROJECT:latest
```

---

## GitLab CI/CD Integration

### Sử dụng Predefined Variables

```yaml
# .gitlab-ci.yml

stages:
  - build

variables:
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
    # Also tag as latest
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
```

### Predefined CI Variables

| Variable | Description |
|----------|-------------|
| `CI_REGISTRY` | `registry.gitlab.com` |
| `CI_REGISTRY_IMAGE` | `registry.gitlab.com/group/project` |
| `CI_REGISTRY_USER` | CI user for auth |
| `CI_REGISTRY_PASSWORD` | CI password/token |
| `CI_COMMIT_SHA` | Git commit SHA |
| `CI_COMMIT_TAG` | Git tag (if tagged) |

### Multi-stage CI Pipeline

```yaml
stages:
  - build
  - test
  - deploy

variables:
  IMAGE: $CI_REGISTRY_IMAGE
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG

test:
  stage: test
  image: $IMAGE_TAG
  script:
    - npm test

deploy:
  stage: deploy
  image: docker:24
  services:
    - docker:24-dind
  only:
    - main
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker pull $IMAGE_TAG
    - docker tag $IMAGE_TAG $IMAGE:latest
    - docker push $IMAGE:latest
```

---

## Multiple Images per Project

```bash
# Project có nhiều services
registry.gitlab.com/mygroup/myproject/frontend:latest
registry.gitlab.com/mygroup/myproject/backend:latest
registry.gitlab.com/mygroup/myproject/worker:latest
```

### Build multiple images

```yaml
# .gitlab-ci.yml
build-frontend:
  script:
    - docker build -t $CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHA -f Dockerfile.frontend .
    - docker push $CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHA

build-backend:
  script:
    - docker build -t $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA -f Dockerfile.backend .
    - docker push $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA
```

---

## Cleanup Policies

### Set via UI

1. Project → **Settings** → **Packages and registries**
2. **Container Registry** → **Cleanup policies**
3. Configure:
   - Keep N tags matching regex
   - Remove tags older than X days
   - Keep tags matching regex

### Cleanup policy example

```yaml
# Keep:
# - Tags matching semver (v1.0.0)
# - Last 5 tags
# Remove:
# - Tags older than 90 days
# - Untagged images
```

---

## Deploy Tokens (for Pull Only)

> Dùng cho servers cần pull image mà không cần push.

1. Project → **Settings** → **Repository**
2. **Deploy tokens** → **Add token**
3. Chọn `read_registry`
4. Sử dụng:

```bash
docker login registry.gitlab.com -u DEPLOY_TOKEN_USERNAME -p DEPLOY_TOKEN
docker pull registry.gitlab.com/group/project:latest
```

---

## Private Registry Access

### Trong Kubernetes

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-registry
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-config>
```

### Tạo secret

```bash
kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=DEPLOY_TOKEN_USER \
  --docker-password=DEPLOY_TOKEN \
  --docker-email=your@email.com
```

---

## Self-hosted GitLab

```bash
# Format cho self-hosted
registry.your-gitlab-domain.com/group/project:tag

# Login
docker login registry.your-gitlab-domain.com
```

---

## Troubleshooting

### "unauthorized: authentication required"

```bash
# Re-login
docker logout registry.gitlab.com
docker login registry.gitlab.com -u USERNAME -p TOKEN
```

### "denied: access forbidden"

```bash
# Kiểm tra:
# 1. Project visibility (private cần auth)
# 2. Token scopes (cần write_registry để push)
# 3. Project permissions (cần Developer+ để push)
```

### "manifest unknown"

```bash
# Image không tồn tại, kiểm tra:
# 1. Đúng path group/project
# 2. Đúng tag
# 3. Image đã được push chưa
```

---

## Quick Commands

```bash
# === FULL WORKFLOW ===

# 1. Set credentials
export GITLAB_USER=your-username
export GITLAB_TOKEN=glpat-xxxxxxxxxxxx
export PROJECT=your-group/your-project

# 2. Login
echo $GITLAB_TOKEN | docker login registry.gitlab.com -u $GITLAB_USER --password-stdin

# 3. Build
docker build -t myapp:latest .

# 4. Tag
docker tag myapp:latest registry.gitlab.com/$PROJECT:latest
docker tag myapp:latest registry.gitlab.com/$PROJECT:v1.0.0

# 5. Push
docker push registry.gitlab.com/$PROJECT:latest
docker push registry.gitlab.com/$PROJECT:v1.0.0

# 6. Pull (verify)
docker pull registry.gitlab.com/$PROJECT:latest
```
