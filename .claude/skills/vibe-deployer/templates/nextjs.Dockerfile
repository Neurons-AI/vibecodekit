# ============================================
# Next.js Dockerfile Template
# Multi-stage build for production
# ============================================
#
# PREREQUISITE: Add this to next.config.js/next.config.mjs:
#
#   /** @type {import('next').NextConfig} */
#   const nextConfig = {
#     output: 'standalone',
#   }
#   module.exports = nextConfig
#
# ============================================

# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Install dependencies for native modules
RUN apk add --no-cache libc6-compat

# Copy package files
COPY package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./

# Install dependencies based on lockfile
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

# Generate Prisma client if prisma exists
RUN if [ -f "prisma/schema.prisma" ]; then npx prisma generate; fi

# Verify standalone output is configured
RUN node -e "const c = require('./next.config.js'); if(c.output !== 'standalone') { console.error('ERROR: next.config.js must have output: standalone'); process.exit(1); }" \
  || node -e "const c = require('./next.config.mjs'); if(c.default?.output !== 'standalone') { console.error('ERROR: next.config.mjs must have output: standalone'); process.exit(1); }" \
  || echo "Skipping standalone check - ensure next.config has output: standalone"

# Build the application
RUN \
  if [ -f yarn.lock ]; then yarn build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm build; \
  else npm run build; \
  fi

# Stage 3: Production Runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy public assets
COPY --from=builder /app/public ./public

# Set correct permissions for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Copy standalone build (these files are created by `output: 'standalone'`)
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy Prisma files if exists (for migrations/schema reference)
# Note: For SQLite, mount the database file as a volume instead of copying
RUN mkdir -p prisma
COPY --from=builder --chown=nextjs:nodejs /app/prisma/schema.prisma ./prisma/ 2>/dev/null || true

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]

# ============================================
# IMPORTANT NOTES:
#
# 1. STANDALONE OUTPUT REQUIRED:
#    Add to next.config.js:
#    module.exports = { output: 'standalone' }
#
# 2. SQLITE DATABASE:
#    Mount as volume in docker-compose.yml:
#    volumes:
#      - ./prisma/dev.db:/app/prisma/dev.db
#
# 3. HEALTH ENDPOINT:
#    Create /app/api/health/route.ts:
#    export async function GET() {
#      return Response.json({ status: 'ok' })
#    }
#
# 4. ENVIRONMENT VARIABLES:
#    - Build-time: Add ARG in Dockerfile
#    - Runtime: Use docker-compose environment section
# ============================================
