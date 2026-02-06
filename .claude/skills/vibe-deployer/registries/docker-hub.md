# Docker Hub

> Registry phổ biến nhất, dễ sử dụng, phù hợp cho beginners và public images.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **URL** | https://hub.docker.com |
| **Free tier** | 1 private repo, unlimited public |
| **Image format** | `docker.io/username/image:tag` hoặc `username/image:tag` |
| **Best for** | Public images, beginners, small projects |

---

## Setup

### 1. Tạo tài khoản

1. Truy cập https://hub.docker.com
2. Click "Sign Up"
3. Điền thông tin và xác nhận email

### 2. Tạo Access Token (Recommended)

> Sử dụng Access Token thay vì password để bảo mật hơn.

1. Login vào Docker Hub
2. Click avatar → **Account Settings**
3. **Security** → **New Access Token**
4. Đặt tên token (e.g., "my-laptop")
5. Chọn permissions: **Read, Write, Delete**
6. Copy và lưu token an toàn

---

## Usage

### Login

```bash
# Login với username/password
docker login

# Login với Access Token (recommended)
docker login -u YOUR_USERNAME
# Nhập Access Token khi được hỏi password

# Login non-interactive (CI/CD)
echo $DOCKER_TOKEN | docker login -u YOUR_USERNAME --password-stdin
```

### Build & Tag

```bash
# Build image
docker build -t myapp:latest .

# Tag cho Docker Hub
docker tag myapp:latest YOUR_USERNAME/myapp:latest
docker tag myapp:latest YOUR_USERNAME/myapp:v1.0.0

# Hoặc build với tag trực tiếp
docker build -t YOUR_USERNAME/myapp:latest .
```

### Push

```bash
# Push single tag
docker push YOUR_USERNAME/myapp:latest

# Push all tags
docker push YOUR_USERNAME/myapp --all-tags

# Push specific version
docker push YOUR_USERNAME/myapp:v1.0.0
```

### Pull

```bash
# Pull image
docker pull YOUR_USERNAME/myapp:latest

# Pull specific version
docker pull YOUR_USERNAME/myapp:v1.0.0
```

---

## Multi-architecture Build

```bash
# Setup buildx (one time)
docker buildx create --name mybuilder --use

# Build và push multi-arch
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t YOUR_USERNAME/myapp:latest \
  --push \
  .
```

---

## Private Repository

### Free tier: 1 private repo

1. Vào Docker Hub → **Repositories** → **Create Repository**
2. Chọn **Private**
3. Hoàn tất

### Pull private image

```bash
# Phải login trước
docker login -u YOUR_USERNAME

# Sau đó pull
docker pull YOUR_USERNAME/private-app:latest
```

---

## Automated Builds (Deprecated)

> Docker Hub đã ngừng Automated Builds miễn phí. Sử dụng GitHub Actions thay thế.

Xem [ci-cd/github-actions.md](../ci-cd/github-actions.md)

---

## CI/CD Integration

### Environment Variables

```bash
DOCKER_USERNAME=your-username
DOCKER_TOKEN=your-access-token
```

### GitHub Actions Example

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    push: true
    tags: ${{ secrets.DOCKER_USERNAME }}/myapp:latest
```

---

## Best Practices

### Naming Convention

```
username/app-name:tag

Examples:
- johndoe/myapi:latest
- johndoe/myapi:v1.0.0
- johndoe/myapi:dev
- johndoe/myapi:sha-abc123
```

### Tags Strategy

| Tag | Purpose |
|-----|---------|
| `latest` | Most recent stable version |
| `v1.0.0` | Semantic versioning |
| `sha-abc123` | Git commit SHA |
| `dev` | Development version |
| `staging` | Staging environment |

---

## Pricing

| Plan | Private Repos | Pulls | Price |
|------|---------------|-------|-------|
| **Free** | 1 | 100/6h (anonymous), 200/6h (authenticated) | $0 |
| **Pro** | Unlimited | 5000/day | $5/month |
| **Team** | Unlimited | Unlimited | $7/user/month |

---

## Troubleshooting

### "denied: requested access to the resource is denied"

```bash
# Nguyên nhân: Chưa login hoặc sai username
docker login -u YOUR_USERNAME
```

### "unauthorized: authentication required"

```bash
# Nguyên nhân: Token hết hạn hoặc sai
# Tạo token mới và login lại
docker logout
docker login -u YOUR_USERNAME
```

### "toomanyrequests: Rate limit exceeded"

```bash
# Nguyên nhân: Vượt quá rate limit
# Giải pháp: Login để tăng limit hoặc đợi reset

# Check rate limit
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/alpine:pull" | jq -r .token)
curl -s -H "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/library/alpine/manifests/latest" -D - -o /dev/null | grep -i rate
```

---

## Quick Commands

```bash
# === FULL WORKFLOW ===

# 1. Login
docker login -u YOUR_USERNAME

# 2. Build
docker build -t myapp:latest .

# 3. Tag
docker tag myapp:latest YOUR_USERNAME/myapp:latest
docker tag myapp:latest YOUR_USERNAME/myapp:v1.0.0

# 4. Push
docker push YOUR_USERNAME/myapp:latest
docker push YOUR_USERNAME/myapp:v1.0.0

# 5. Verify
docker pull YOUR_USERNAME/myapp:latest
```
