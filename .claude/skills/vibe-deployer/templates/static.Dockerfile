# ============================================
# Static Site Dockerfile Template
# Nginx-based for serving static files
# ============================================

# ==================== OPTION 1: Pre-built static files ====================
# Use this when you have already built your React/Vue/Angular app

FROM nginx:1.25-alpine AS runner

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/

# Copy static files
COPY dist/ /usr/share/nginx/html/
# Or for other build outputs:
# COPY build/ /usr/share/nginx/html/
# COPY out/ /usr/share/nginx/html/
# COPY public/ /usr/share/nginx/html/

# Create non-root user (nginx alpine already has nginx user)
RUN chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

CMD ["nginx", "-g", "daemon off;"]


# ==================== OPTION 2: Build and serve (React/Vue/Angular) ====================
# Uncomment below for full build pipeline

# # Stage 1: Build
# FROM node:20-alpine AS builder
#
# WORKDIR /app
#
# # Copy package files
# COPY package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./
#
# # Install dependencies
# RUN \
#     if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
#     elif [ -f package-lock.json ]; then npm ci; \
#     elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
#     else npm install; \
#     fi
#
# # Copy source code
# COPY . .
#
# # Build the application
# RUN npm run build
#
# # Stage 2: Serve with Nginx
# FROM nginx:1.25-alpine AS runner
#
# # Copy nginx config
# COPY nginx.conf /etc/nginx/conf.d/default.conf
#
# # Copy built files from builder
# COPY --from=builder /app/dist /usr/share/nginx/html
# # Or: COPY --from=builder /app/build /usr/share/nginx/html
#
# RUN chown -R nginx:nginx /usr/share/nginx/html
#
# USER nginx
# EXPOSE 80
#
# HEALTHCHECK --interval=30s --timeout=3s \
#     CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1
#
# CMD ["nginx", "-g", "daemon off;"]


# ============================================
# NGINX CONFIG TEMPLATE (save as nginx.conf)
# ============================================
# server {
#     listen 80;
#     server_name localhost;
#     root /usr/share/nginx/html;
#     index index.html;
#
#     # Gzip compression
#     gzip on;
#     gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
#
#     # SPA routing - serve index.html for all routes
#     location / {
#         try_files $uri $uri/ /index.html;
#     }
#
#     # Health check endpoint
#     location /health {
#         access_log off;
#         return 200 "healthy\n";
#         add_header Content-Type text/plain;
#     }
#
#     # Cache static assets
#     location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
#         expires 1y;
#         add_header Cache-Control "public, immutable";
#     }
#
#     # Security headers
#     add_header X-Frame-Options "SAMEORIGIN" always;
#     add_header X-Content-Type-Options "nosniff" always;
#     add_header X-XSS-Protection "1; mode=block" always;
# }
# ============================================

# ============================================
# NOTES:
# - Create nginx.conf file based on template above
# - For React: build output is in "build/" folder
# - For Vue/Vite: build output is in "dist/" folder
# - For Angular: build output is in "dist/project-name/"
# - For Next.js static export: use "out/" folder
# ============================================
