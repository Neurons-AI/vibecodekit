# ============================================
# PHP/Laravel Dockerfile Template
# Multi-stage build for production
# ============================================

# Stage 1: Composer Dependencies
FROM composer:2 AS vendor

WORKDIR /app

# Copy composer files
COPY composer.json composer.lock* ./

# Install dependencies (no dev for production)
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --no-autoloader \
    --prefer-dist

# Copy application code for autoload optimization
COPY . .

# Generate optimized autoload
RUN composer dump-autoload --optimize --no-dev

# Stage 2: Frontend Assets (if using Laravel Mix/Vite)
FROM node:20-alpine AS frontend

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* yarn.lock* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else echo "No JS dependencies"; fi

# Copy source files
COPY . .

# Build assets (Laravel Mix or Vite)
RUN if [ -f "vite.config.js" ]; then npm run build; \
    elif [ -f "webpack.mix.js" ]; then npm run production; \
    else echo "No frontend build needed"; fi

# Stage 3: Production Runner
FROM php:8.3-fpm-alpine AS runner

WORKDIR /var/www/html

# Install PHP extensions
RUN apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    gd \
    zip \
    intl \
    mbstring \
    opcache \
    bcmath \
    && rm -rf /var/cache/apk/*

# Install Redis extension (optional)
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/app.ini
# If no custom config, use these defaults:
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini

# Create non-root user
RUN addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

# Copy application from vendor stage
COPY --from=vendor --chown=appuser:appgroup /app/vendor ./vendor

# Copy built frontend assets
COPY --from=frontend --chown=appuser:appgroup /app/public/build ./public/build

# Copy application code
COPY --chown=appuser:appgroup . .

# Remove unnecessary files
RUN rm -rf \
    tests \
    .git \
    .env* \
    docker \
    node_modules \
    storage/logs/* \
    storage/framework/cache/* \
    storage/framework/sessions/* \
    storage/framework/views/*

# Set permissions for Laravel
RUN chown -R appuser:appgroup storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

USER appuser

EXPOSE 9000

# Health check using PHP-FPM ping
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm-healthcheck || exit 1

CMD ["php-fpm"]

# ============================================
# NOTES:
# - Use with nginx reverse proxy (see docker-compose)
# - For artisan commands: docker-compose exec app php artisan ...
# - Copy .env.example to .env and configure
# - Run: php artisan key:generate
# - Run: php artisan migrate
# ============================================

# ============================================
# ALTERNATIVE: Apache version (simpler, all-in-one)
# ============================================
# FROM php:8.3-apache AS runner-apache
#
# RUN a2enmod rewrite
# ENV APACHE_DOCUMENT_ROOT /var/www/html/public
# RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
#     /etc/apache2/sites-available/*.conf
#
# COPY --from=vendor /app/vendor ./vendor
# COPY . .
#
# EXPOSE 80
# CMD ["apache2-foreground"]
# ============================================
