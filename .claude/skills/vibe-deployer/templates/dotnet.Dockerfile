# ============================================
# .NET Core Dockerfile Template
# Multi-stage build for production
# ============================================

# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS builder

WORKDIR /src

# Copy csproj and restore dependencies (cached layer)
COPY *.sln ./
COPY **/*.csproj ./

# Restore packages
RUN dotnet restore

# Copy everything else
COPY . .

# Build and publish
RUN dotnet publish -c Release -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

# Stage 2: Production Runner
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 dotnetuser \
    && adduser --system --uid 1001 --ingroup dotnetuser dotnetuser

# Copy published output
COPY --from=builder --chown=dotnetuser:dotnetuser /app/publish .

USER dotnetuser

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Enable globalization (optional, increases image size)
# ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
# RUN apk add --no-cache icu-libs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "YourApp.dll"]

# ============================================
# ALTERNATIVE: Self-contained deployment
# Larger image but no runtime dependency
# ============================================
# FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS builder
#
# WORKDIR /src
# COPY . .
#
# RUN dotnet publish -c Release -o /app/publish \
#     --self-contained true \
#     -r linux-musl-x64 \
#     /p:PublishSingleFile=true \
#     /p:PublishTrimmed=true
#
# FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine AS runner
#
# WORKDIR /app
# COPY --from=builder /app/publish .
#
# USER 1001
# EXPOSE 8080
#
# ENTRYPOINT ["./YourApp"]
# ============================================

# ============================================
# NOTES:
# - Replace "YourApp.dll" with your actual DLL name
# - Add health endpoint in Program.cs:
#   app.MapHealthChecks("/health");
# - For EF Core migrations, create entrypoint script
# - Alpine images are smaller but may have compatibility issues
#   Use Debian-based images if needed:
#   mcr.microsoft.com/dotnet/aspnet:8.0
# ============================================
