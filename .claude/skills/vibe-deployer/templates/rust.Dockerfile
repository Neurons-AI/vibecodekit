# ============================================
# Rust Dockerfile Template
# Multi-stage build for production
# ============================================

# Stage 1: Build
FROM rust:1.75-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache musl-dev pkgconfig openssl-dev

# Create a new empty shell project for dependency caching
RUN cargo new --bin app
WORKDIR /app/app

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Build dependencies only (cached layer)
RUN cargo build --release && rm -rf src

# Copy actual source code
COPY src ./src

# Build the actual application
RUN touch src/main.rs && cargo build --release

# Stage 2: Production Runner (Distroless)
FROM gcr.io/distroless/cc-debian12 AS runner

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/app/target/release/app /app/server

# Distroless runs as nonroot by default
USER nonroot:nonroot

EXPOSE 8080
ENV PORT=8080

# Distroless doesn't support HEALTHCHECK
# Use orchestrator health checks instead

ENTRYPOINT ["/app/server"]

# ============================================
# ALTERNATIVE: Alpine-based runner (has shell, smaller)
# ============================================
# FROM alpine:3.19 AS runner-alpine
#
# RUN apk add --no-cache ca-certificates libgcc
#
# RUN addgroup -S appgroup && adduser -S appuser -G appgroup
#
# WORKDIR /app
# COPY --from=builder /app/app/target/release/app ./server
#
# USER appuser
# EXPOSE 8080
#
# HEALTHCHECK --interval=30s --timeout=3s \
#     CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
#
# CMD ["./server"]
# ============================================

# ============================================
# ALTERNATIVE: Debian-based (for more compatibility)
# ============================================
# FROM rust:1.75-slim AS builder
#
# WORKDIR /app
# RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
#
# COPY . .
# RUN cargo build --release
#
# FROM debian:bookworm-slim AS runner
#
# RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
# RUN useradd -m -u 1001 appuser
#
# WORKDIR /app
# COPY --from=builder /app/target/release/app ./server
#
# USER appuser
# EXPOSE 8080
#
# CMD ["./server"]
# ============================================

# ============================================
# NOTES:
# - Replace "app" with your actual binary name (from Cargo.toml)
# - For Actix-web, Axum, Rocket: same Dockerfile works
# - If using OpenSSL, need libssl in runtime image
# - For static linking: RUSTFLAGS='-C target-feature=+crt-static'
# - Build for musl: --target x86_64-unknown-linux-musl
# ============================================
