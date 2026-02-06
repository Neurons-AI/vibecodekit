# Docker Deployment Checklist

> Checklist đầy đủ để đảm bảo Docker deployment an toàn và tối ưu.

---

## Pre-Deployment

### Project Analysis
- [ ] Xác định project type (Next.js, Node.js, Python, Go, PHP, Java, .NET, Rust, Static)
- [ ] Xác định package manager (npm, yarn, pnpm, pip, poetry, composer, maven, gradle, cargo)
- [ ] Xác định runtime version cần thiết
- [ ] Xác định build commands
- [ ] Xác định start/run commands
- [ ] Xác định port cần expose
- [ ] Xác định database type (SQLite, PostgreSQL, MySQL, MongoDB, Redis)

### Environment Variables
- [ ] List tất cả env vars cần thiết
- [ ] Phân loại: build-time vs runtime
- [ ] Xác nhận KHÔNG hardcode secrets
- [ ] Tạo `.env.example` file
- [ ] Document tất cả required env vars

---

## Dockerfile Checklist

### Base Image
- [ ] Sử dụng official image
- [ ] Pin version cụ thể (KHÔNG dùng `latest`)
- [ ] Sử dụng Alpine/Slim variant nếu có thể
- [ ] Ví dụ tốt:
  - `node:20-alpine`
  - `python:3.12-slim`
  - `php:8.3-fpm-alpine`
  - `eclipse-temurin:21-jre-alpine`
  - `mcr.microsoft.com/dotnet/aspnet:8.0-alpine`

### Multi-stage Build
- [ ] Stage 1: Dependencies (install packages)
- [ ] Stage 2: Builder (build application)
- [ ] Stage 3: Runner (production only)
- [ ] Final image chỉ chứa production code
- [ ] Verify image size hợp lý (< 500MB cho hầu hết apps)

### Security
- [ ] Tạo non-root user
- [ ] Sử dụng `USER` instruction
- [ ] KHÔNG copy `.env` files
- [ ] KHÔNG install dev dependencies trong final stage
- [ ] KHÔNG expose unnecessary ports
- [ ] Scan image với `docker scan` hoặc Trivy

### Optimization
- [ ] Tận dụng layer caching (copy package files trước)
- [ ] Sử dụng `.dockerignore`
- [ ] Xóa cache và temp files
- [ ] Combine RUN commands khi có thể
- [ ] Order instructions từ ít thay đổi → thay đổi nhiều

### Health Check
- [ ] Thêm `HEALTHCHECK` instruction (trừ distroless)
- [ ] Tạo `/health` hoặc `/api/health` endpoint
- [ ] Set interval, timeout, retries hợp lý:
  - `interval`: 30s
  - `timeout`: 3-5s
  - `start_period`: 10-30s (tùy app startup time)
  - `retries`: 3

---

## Docker Compose Checklist

### Development
- [ ] Mount source code với volumes
- [ ] Exclude node_modules/vendor từ mount
- [ ] Set restart policy: `unless-stopped`
- [ ] Configure health checks
- [ ] Expose ports cho debugging

### Production
- [ ] Set restart policy: `always`
- [ ] Configure resource limits (CPU, memory)
- [ ] Configure logging (max-size, max-file)
- [ ] Set up reverse proxy (nginx/traefik)
- [ ] KHÔNG expose database ports publicly
- [ ] Use env_file cho secrets

### Networking
- [ ] Tạo custom network
- [ ] Internal services không expose public
- [ ] Chỉ expose ports cần thiết
- [ ] Use service names cho internal communication

---

## Database Considerations

### SQLite
- [ ] Mount volume cho database file
- [ ] Đảm bảo permissions đúng
- [ ] Setup backup strategy
- [ ] Xem xét dùng PostgreSQL cho production

### PostgreSQL
- [ ] Sử dụng named volume cho data
- [ ] Configure health check
- [ ] Set secure passwords (không dùng default)
- [ ] Backup strategy với pg_dump
- [ ] KHÔNG expose port 5432 publicly trong production

### MySQL
- [ ] Sử dụng named volume cho data
- [ ] Configure health check
- [ ] Set secure passwords
- [ ] Backup strategy với mysqldump

### MongoDB
- [ ] Sử dụng named volume cho data
- [ ] Enable authentication
- [ ] Configure health check

### Redis
- [ ] Configure persistence nếu cần (`appendonly yes`)
- [ ] Set memory limits (`maxmemory`)
- [ ] Configure eviction policy

---

## Security Checklist

### Secrets Management
- [ ] KHÔNG commit .env files
- [ ] KHÔNG hardcode secrets trong code
- [ ] KHÔNG copy .env vào Docker image
- [ ] Sử dụng Docker secrets hoặc env vars
- [ ] Rotate secrets định kỳ

### Image Security
- [ ] Use official base images
- [ ] Keep images updated
- [ ] Scan for vulnerabilities:
  ```bash
  docker scan myapp:latest
  # hoặc
  trivy image myapp:latest
  ```
- [ ] Don't run as root
- [ ] Minimize installed packages

### Network Security
- [ ] Use internal networks cho database
- [ ] Enable HTTPS/TLS
- [ ] Configure firewall rules
- [ ] Rate limiting trên reverse proxy

---

## Pre-Build Verification

```bash
# Verify .dockerignore exists
[ -f .dockerignore ] && echo "✓ .dockerignore exists" || echo "✗ MISSING .dockerignore"

# Verify no secrets in Dockerfile
grep -i "password\|secret\|key\|token" Dockerfile && echo "⚠ WARNING: Possible secrets!" || echo "✓ No obvious secrets"

# Verify multi-stage build
stages=$(grep -c "^FROM.*AS" Dockerfile)
echo "Found $stages build stages"

# Verify non-root user
grep -q "^USER" Dockerfile && echo "✓ Non-root user configured" || echo "⚠ Consider adding non-root user"

# Verify health check
grep -q "HEALTHCHECK" Dockerfile && echo "✓ Health check configured" || echo "⚠ Consider adding health check"
```

---

## Build & Test

```bash
# Build image
docker build -t myapp:latest .

# Check image size
docker images myapp:latest --format "{{.Size}}"

# Run container
docker run -d -p 3000:3000 --name myapp-test myapp:latest

# Test health endpoint
curl http://localhost:3000/health

# Check logs
docker logs myapp-test

# Check resource usage
docker stats myapp-test --no-stream

# Cleanup
docker stop myapp-test && docker rm myapp-test
```

---

## Production Deployment

### Before Deploy
- [ ] Build với production tag (e.g., `v1.0.0`)
- [ ] Test locally với production config
- [ ] Verify all env vars configured
- [ ] Run database migrations
- [ ] Backup existing data

### Deploy Commands
```bash
# Build production image
docker build -t myapp:v1.0.0 .

# Tag for registry (optional)
docker tag myapp:v1.0.0 registry.example.com/myapp:v1.0.0

# Push to registry (optional)
docker push registry.example.com/myapp:v1.0.0

# Deploy với docker-compose
docker-compose -f docker-compose.prod.yml up -d --build

# Verify deployment
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
```

### Post-Deploy
- [ ] Verify health checks passing
- [ ] Check application logs for errors
- [ ] Test critical functionality
- [ ] Monitor resource usage
- [ ] Verify backup system working
- [ ] Update documentation if needed

---

## Troubleshooting Quick Reference

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| `COPY failed: file not found` | File in .dockerignore or missing | Check .dockerignore, verify file exists |
| `permission denied` | Wrong file permissions | Check USER instruction, volume permissions |
| `port already in use` | Port conflict | Change host port mapping |
| `out of memory` | Container memory limit | Increase memory limit or optimize app |
| `health check failing` | App not responding | Increase start_period, verify endpoint exists |
| `module not found` | Missing dependencies | Check if deps installed in correct stage |
| `connection refused` to database | Database not ready | Add depends_on with health check |
| `image too large` | Not using multi-stage or .dockerignore | Review build stages and .dockerignore |

---

## Useful Commands Reference

```bash
# === BUILD ===
docker build -t myapp .
docker build -t myapp:v1.0.0 --no-cache .
docker build --target builder -t myapp:dev .

# === RUN ===
docker run -d -p 3000:3000 myapp
docker run -it myapp sh  # Interactive shell
docker run --env-file .env myapp

# === COMPOSE ===
docker-compose up -d
docker-compose up -d --build
docker-compose down
docker-compose logs -f
docker-compose exec app sh

# === DEBUG ===
docker logs container_name
docker exec -it container_name sh
docker inspect container_name
docker stats

# === CLEANUP ===
docker system prune -f
docker image prune -f
docker volume prune -f
docker container prune -f
```

---

**Last updated:** 2024
