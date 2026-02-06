# ============================================
# Go Dockerfile Template
# Multi-stage build for production
# ============================================

# Stage 1: Builder
FROM golang:1.22-alpine AS builder
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Download dependencies first (cached layer)
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o /app/server ./cmd/server

# Alternative: Build from main.go
# RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
#     -ldflags='-w -s' \
#     -o /app/server .

# Stage 2: Production Runner (Distroless)
FROM gcr.io/distroless/static-debian12 AS runner

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/server /app/server

# Copy static files if needed
# COPY --from=builder /app/static ./static
# COPY --from=builder /app/templates ./templates

# Run as non-root (distroless default is nonroot)
USER nonroot:nonroot

EXPOSE 8080
ENV PORT=8080

# Distroless doesn't support HEALTHCHECK in Dockerfile
# Use orchestrator health checks instead (Kubernetes, Docker Compose)

ENTRYPOINT ["/app/server"]

# ============================================
# ALTERNATIVE: Alpine-based runner (smaller, has shell)
# ============================================
# FROM alpine:3.19 AS runner-alpine
#
# RUN apk --no-cache add ca-certificates tzdata
# RUN addgroup -S appgroup && adduser -S appuser -G appgroup
#
# WORKDIR /app
# COPY --from=builder /app/server .
#
# USER appuser
# EXPOSE 8080
#
# HEALTHCHECK --interval=30s --timeout=3s \
#   CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
#
# CMD ["./server"]
# ============================================
