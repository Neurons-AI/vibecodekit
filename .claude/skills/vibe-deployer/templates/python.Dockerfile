# ============================================
# Python Dockerfile Template
# Multi-stage build for production
# ============================================

# Stage 1: Builder
FROM python:3.12-slim AS builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements*.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Alternative: Poetry
# COPY pyproject.toml poetry.lock* ./
# RUN pip install poetry && \
#     poetry config virtualenvs.create false && \
#     poetry install --no-dev --no-interaction --no-ansi

# Stage 2: Production Runner
FROM python:3.12-slim AS runner
WORKDIR /app

# Create non-root user
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY --chown=appuser:appgroup . .

# Remove unnecessary files
RUN rm -rf tests/ docs/ *.md .git* .env*

USER appuser

# Default port
EXPOSE 8000
ENV PORT=8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:${PORT}/health || exit 1

# Default command - adjust based on framework
# FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

# Flask
# CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]

# Django
# CMD ["gunicorn", "--bind", "0.0.0.0:8000", "project.wsgi:application"]

# ============================================
# NOTES:
# - Adjust CMD based on your framework
# - For Django, run migrations in entrypoint script
# - Consider using gunicorn for production
# ============================================
