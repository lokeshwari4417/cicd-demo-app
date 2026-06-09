#!/bin/bash
# ============================================================
#  scripts/deploy.sh
#  Manual deployment script - pulls latest Docker image
#  and restarts the application container.
#
#  Usage:
#    ./deploy.sh [IMAGE_TAG]
#    ./deploy.sh latest
#    ./deploy.sh sha-abc1234
# ============================================================

set -e

# ---- Configuration ----
DOCKER_IMAGE="${DOCKERHUB_USERNAME:-yourusername}/cicd-demo-app"
IMAGE_TAG="${1:-latest}"
CONTAINER_NAME="cicd-demo-app"
APP_PORT="3000"
LOG_FILE="/opt/cicd-app/logs/deploy.log"
MAX_HEALTH_RETRIES=10
HEALTH_INTERVAL=3

# ---- Logging function ----
log() {
    local MSG="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$MSG"
    mkdir -p "$(dirname $LOG_FILE)"
    echo "$MSG" >> "$LOG_FILE"
}

# ---- Health check function ----
health_check() {
    local RETRIES=0
    log "Running health check..."
    while [ $RETRIES -lt $MAX_HEALTH_RETRIES ]; do
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT}/health 2>/dev/null || echo "000")
        if [ "$HTTP_STATUS" == "200" ]; then
            log "✅ Health check passed! (HTTP $HTTP_STATUS)"
            return 0
        fi
        RETRIES=$((RETRIES + 1))
        log "  Attempt $RETRIES/$MAX_HEALTH_RETRIES failed (HTTP $HTTP_STATUS), retrying in ${HEALTH_INTERVAL}s..."
        sleep $HEALTH_INTERVAL
    done
    log "❌ Health check failed after $MAX_HEALTH_RETRIES attempts!"
    return 1
}

# ---- Rollback function ----
rollback() {
    log "⚠️  Starting rollback to previous container..."
    docker stop ${CONTAINER_NAME}_new 2>/dev/null || true
    docker rm ${CONTAINER_NAME}_new 2>/dev/null || true
    if docker inspect ${CONTAINER_NAME}_backup &>/dev/null; then
        docker rename ${CONTAINER_NAME}_backup $CONTAINER_NAME 2>/dev/null || true
        docker start $CONTAINER_NAME 2>/dev/null || true
        log "Rollback complete."
    else
        log "No backup container found for rollback."
    fi
}

# ============================================================
# MAIN DEPLOYMENT FLOW
# ============================================================

log "========================================"
log " Starting Deployment"
log " Image  : ${DOCKER_IMAGE}:${IMAGE_TAG}"
log " Host   : $(hostname)"
log "========================================"

# Step 1: Pull new image
log "[1/6] Pulling Docker image: ${DOCKER_IMAGE}:${IMAGE_TAG}..."
docker pull "${DOCKER_IMAGE}:${IMAGE_TAG}"
log "Image pulled successfully."

# Step 2: Create backup of running container
log "[2/6] Creating backup of current container..."
if docker inspect $CONTAINER_NAME &>/dev/null; then
    docker rename $CONTAINER_NAME ${CONTAINER_NAME}_backup 2>/dev/null || true
    log "Backup created: ${CONTAINER_NAME}_backup"
else
    log "No existing container to backup."
fi

# Step 3: Stop old container
log "[3/6] Stopping old container..."
docker stop ${CONTAINER_NAME}_backup 2>/dev/null || true
log "Old container stopped."

# Step 4: Start new container
log "[4/6] Starting new container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p ${APP_PORT}:3000 \
    -e NODE_ENV=production \
    -e APP_VERSION="${IMAGE_TAG}" \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    "${DOCKER_IMAGE}:${IMAGE_TAG}"

log "New container started: $CONTAINER_NAME"

# Step 5: Health check
log "[5/6] Running health check..."
sleep 5
if health_check; then
    log "✅ New container is healthy!"
else
    log "❌ New container failed health check — rolling back!"
    rollback
    exit 1
fi

# Step 6: Cleanup
log "[6/6] Cleaning up..."
docker rm ${CONTAINER_NAME}_backup 2>/dev/null || true
docker image prune -f
log "Cleanup complete."

log "========================================"
log " Deployment Successful! 🚀"
log " Container : $CONTAINER_NAME"
log " Port      : $APP_PORT"
log " Image     : ${DOCKER_IMAGE}:${IMAGE_TAG}"
log "========================================"
