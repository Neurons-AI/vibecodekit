# GitHub Container Registry (GHCR)

> Registry miễn phí của GitHub, tích hợp tốt với GitHub repos và Actions.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://ghcr.io |
| **Free tier** | Unlimited private repos (với GitHub account) |
| **Image format** | `ghcr.io/OWNER/IMAGE:TAG` |
| **Best for** | GitHub projects, private images miễn phí |

---

## Setup

### 1. Tạo Personal Access Token (PAT)

1. GitHub → **Settings** → **Developer settings**
2. **Personal access tokens** → **Tokens (classic)**
3. **Generate new token (classic)**
4. Chọn scopes:
   - `write:packages` - Push images
   - `read:packages` - Pull images
   - `delete:packages` - Delete images (optional)
5. Copy và lưu token an toàn

### 2. Login vào GHCR

```bash
# Login với PAT
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Hoặc interactive
docker login ghcr.io -u YOUR_GITHUB_USERNAME
# Nhập PAT khi được hỏi password
```

---

## Usage

### Build & Tag

```bash
# Build image
docker build -t myapp:latest .

# Tag cho GHCR
# Format: ghcr.io/OWNER/IMAGE:TAG
# OWNER = username hoặc organization

docker tag myapp:latest ghcr.io/YOUR_USERNAME/myapp:latest
docker tag myapp:latest ghcr.io/YOUR_USERNAME/myapp:v1.0.0

# Hoặc build với tag trực tiếp
docker build -t ghcr.io/YOUR_USERNAME/myapp:latest .
```

### Push

```bash
# Push image
docker push ghcr.io/YOUR_USERNAME/myapp:latest
docker push ghcr.io/YOUR_USERNAME/myapp:v1.0.0
```

### Pull

```bash
# Pull image
docker pull ghcr.io/YOUR_USERNAME/myapp:latest
```

---

## Visibility Settings

### Mặc định: Private

Sau khi push lần đầu, image sẽ là private.

### Chuyển sang Public

1. GitHub → **Your profile** → **Packages**
2. Click vào package
3. **Package settings** (sidebar phải)
4. **Danger Zone** → **Change visibility** → **Public**

### Link với Repository

1. Vào package settings
2. **Connect Repository**
3. Chọn repo

**Lợi ích:**
- Hiển thị package trong repo
- Kế thừa permissions từ repo
- README từ repo

---

## GitHub Actions Integration

### Sử dụng GITHUB_TOKEN (Recommended)

```yaml
name: Build and Push

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### Multi-architecture Build

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ghcr.io/${{ github.repository }}:latest
```

---

## Organization Packages

### Push to org

```bash
# Tag với org name
docker tag myapp:latest ghcr.io/YOUR_ORG/myapp:latest
docker push ghcr.io/YOUR_ORG/myapp:latest
```

### Permissions

- Cần quyền `write:packages` trong org
- Admin có thể set visibility và permissions trong org settings

---

## Labels và Metadata

### Thêm labels trong Dockerfile

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
LABEL org.opencontainers.image.description="My app description"
LABEL org.opencontainers.image.licenses="MIT"
```

### Auto-link với repo

```dockerfile
# Thêm label này để auto-link
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
```

---

## Delete Images

### Via Web UI

1. GitHub → **Packages** → Select package
2. **Package versions** (sidebar)
3. Click version → **Delete**

### Via API

```bash
# List versions
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user/packages/container/myapp/versions

# Delete version
curl -X DELETE -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user/packages/container/myapp/versions/VERSION_ID
```

---

## Pricing

| Plan | Storage | Data Transfer |
|------|---------|---------------|
| **Free** | 500MB | 1GB/month |
| **Pro** | 2GB | 10GB/month |
| **Team** | 2GB | 10GB/month |
| **Enterprise** | 50GB | 100GB/month |

> **Note:** Public packages không tính vào storage/transfer limits

---

## Troubleshooting

### "unauthorized"

```bash
# Kiểm tra token có đúng scopes không
# Cần: write:packages, read:packages

# Re-login
docker logout ghcr.io
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

### "denied: permission_denied"

```bash
# Nguyên nhân: Không có quyền push
# Giải pháp: Kiểm tra PAT scopes và org permissions
```

### Image không hiện trong Packages

```dockerfile
# Thêm label để link với repo
LABEL org.opencontainers.image.source="https://github.com/USERNAME/REPO"
```

---

## Quick Commands

```bash
# === FULL WORKFLOW ===

# 1. Set token
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx

# 2. Login
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 3. Build
docker build -t myapp:latest .

# 4. Tag
docker tag myapp:latest ghcr.io/YOUR_USERNAME/myapp:latest
docker tag myapp:latest ghcr.io/YOUR_USERNAME/myapp:v1.0.0

# 5. Push
docker push ghcr.io/YOUR_USERNAME/myapp:latest
docker push ghcr.io/YOUR_USERNAME/myapp:v1.0.0

# 6. Pull (test)
docker pull ghcr.io/YOUR_USERNAME/myapp:latest
```
