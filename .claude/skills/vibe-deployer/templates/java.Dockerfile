# ============================================
# Java/Spring Boot Dockerfile Template
# Multi-stage build for production
# ============================================

# ==================== MAVEN VERSION ====================

# Stage 1: Build with Maven
FROM eclipse-temurin:21-jdk-alpine AS builder-maven

WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

# Copy pom.xml first for dependency caching
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./

# Download dependencies (cached layer)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn package -DskipTests -B

# Extract layers for better caching (Spring Boot 2.3+)
RUN java -Djarmode=layertools -jar target/*.jar extract

# Stage 2: Production Runner
FROM eclipse-temurin:21-jre-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 javauser \
    && adduser --system --uid 1001 --ingroup javauser javauser

# Copy layers from builder (for better Docker caching)
COPY --from=builder-maven --chown=javauser:javauser /app/dependencies/ ./
COPY --from=builder-maven --chown=javauser:javauser /app/spring-boot-loader/ ./
COPY --from=builder-maven --chown=javauser:javauser /app/snapshot-dependencies/ ./
COPY --from=builder-maven --chown=javauser:javauser /app/application/ ./

USER javauser

EXPOSE 8080
ENV PORT=8080

# JVM tuning for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run with layered jar
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]

# ==================== GRADLE VERSION ====================
# Uncomment below if using Gradle instead of Maven

# FROM eclipse-temurin:21-jdk-alpine AS builder-gradle
#
# WORKDIR /app
#
# # Copy Gradle wrapper
# COPY gradlew ./
# COPY gradle ./gradle
# COPY build.gradle* settings.gradle* ./
#
# # Download dependencies
# RUN ./gradlew dependencies --no-daemon
#
# # Copy source and build
# COPY src ./src
# RUN ./gradlew bootJar --no-daemon -x test
#
# # Extract layers
# RUN java -Djarmode=layertools -jar build/libs/*.jar extract
#
# # ... same runner stage as above

# ============================================
# NOTES:
# - Requires Spring Boot 2.3+ for layered jars
# - Add spring-boot-starter-actuator for health endpoint
# - JVM will auto-detect container memory limits
# - For older Spring Boot, use simple JAR copy:
#   COPY --from=builder /app/target/*.jar app.jar
#   ENTRYPOINT ["java", "-jar", "app.jar"]
# ============================================
