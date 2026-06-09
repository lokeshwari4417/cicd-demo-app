# ============================================================
#  Dockerfile - CI/CD Pipeline Demo App
#  Multi-stage build for optimized production image
# ============================================================

# ---- Stage 1: Dependencies ----
FROM node:18-alpine AS deps

# Set working directory
WORKDIR /app

# Copy package files first (Docker cache optimization)
# Only re-runs npm install if package.json changes
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force


# ---- Stage 2: Production image ----
FROM node:18-alpine AS production

# Add metadata labels
LABEL maintainer="T. Lokeshwari <lokeshwari@example.com>"
LABEL version="1.0.0"
LABEL description="CI/CD Pipeline Demo Application"

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copy production dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source code
COPY src/ ./src/
COPY public/ ./public/
COPY package.json ./

# Set correct ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user (security best practice)
USER appuser

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose application port
EXPOSE 3000

# Health check - Docker will monitor container health
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "src/server.js"]
