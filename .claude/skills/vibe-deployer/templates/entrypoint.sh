#!/bin/sh
# ============================================
# Docker Entrypoint Script Template
# Handles startup tasks before running the app
# ============================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==================== WAIT FOR DEPENDENCIES ====================
wait_for_service() {
    local host=$1
    local port=$2
    local max_attempts=${3:-30}
    local attempt=1

    log_info "Waiting for $host:$port..."

    while ! nc -z "$host" "$port" 2>/dev/null; do
        if [ $attempt -ge $max_attempts ]; then
            log_error "Service $host:$port not available after $max_attempts attempts"
            exit 1
        fi
        log_warn "Attempt $attempt/$max_attempts - $host:$port not ready, waiting..."
        attempt=$((attempt + 1))
        sleep 2
    done

    log_info "$host:$port is ready!"
}

# Wait for database if DATABASE_URL is set
if [ -n "$DATABASE_URL" ]; then
    # Extract host and port from DATABASE_URL
    # Supports: postgresql://user:pass@host:port/db
    DB_HOST=$(echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    DB_PORT=$(echo "$DATABASE_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')

    if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
        wait_for_service "$DB_HOST" "$DB_PORT"
    fi
fi

# Wait for Redis if REDIS_URL is set
if [ -n "$REDIS_URL" ]; then
    REDIS_HOST=$(echo "$REDIS_URL" | sed -n 's/.*\/\/\([^:]*\):.*/\1/p')
    REDIS_PORT=$(echo "$REDIS_URL" | sed -n 's/.*:\([0-9]*\).*/\1/p')

    if [ -n "$REDIS_HOST" ] && [ -n "$REDIS_PORT" ]; then
        wait_for_service "$REDIS_HOST" "$REDIS_PORT"
    fi
fi

# ==================== DATABASE MIGRATIONS ====================

# Node.js / Prisma
if [ -f "prisma/schema.prisma" ]; then
    log_info "Running Prisma migrations..."
    npx prisma migrate deploy
    log_info "Prisma migrations completed"
fi

# Python / Django
if [ -f "manage.py" ]; then
    log_info "Running Django migrations..."
    python manage.py migrate --noinput
    python manage.py collectstatic --noinput
    log_info "Django setup completed"
fi

# Python / Alembic (FastAPI/Flask)
if [ -f "alembic.ini" ]; then
    log_info "Running Alembic migrations..."
    alembic upgrade head
    log_info "Alembic migrations completed"
fi

# PHP / Laravel
if [ -f "artisan" ]; then
    log_info "Running Laravel setup..."

    # Generate key if not set
    if [ -z "$APP_KEY" ]; then
        php artisan key:generate --force
    fi

    # Run migrations
    php artisan migrate --force

    # Clear and cache
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache

    log_info "Laravel setup completed"
fi

# Java / Flyway
if [ -f "flyway.conf" ] || [ -d "src/main/resources/db/migration" ]; then
    log_info "Running Flyway migrations..."
    # Migrations are usually run by Spring Boot automatically
    log_info "Flyway migrations will run on application start"
fi

# ==================== HEALTH CHECK FILE ====================
# Create a file to indicate the container is ready
touch /tmp/container-ready

log_info "Container initialization complete!"

# ==================== EXECUTE MAIN COMMAND ====================
exec "$@"

# ============================================
# USAGE IN DOCKERFILE:
#
# COPY entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh
# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["node", "server.js"]
#
# Or for shell form (allows variable expansion):
# ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
# ============================================

# ============================================
# NOTES:
# - Install netcat (nc) in your image: apk add --no-cache netcat-openbsd
# - Adjust wait timeouts based on your infrastructure
# - Add more service checks as needed (Elasticsearch, RabbitMQ, etc.)
# - For production, consider using docker-compose depends_on with healthcheck
# ============================================
