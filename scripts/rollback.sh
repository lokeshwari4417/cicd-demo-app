#!/bin/bash
# ============================================================
#  scripts/rollback.sh
#  Rolls back the application to a previous Docker image.
#
#  Usage:
#    ./rollback.sh                     # Rolls back to previous tag
#    ./rollback.sh sha-abc1234         # Rolls back to specific tag
# ============================================================

set -e

DOCKER_IMAGE="${DOCKERHUB_USERNAME:-yourusername}/cicd-demo-app"
ROLLBACK_TAG="${1:-}"
CONTAINER_NAME="cicd-demo-app"
APP_PORT="3000"
LOG_FILE="/opt/cicd-app/logs/rollback.log"

log() {
    local MSG="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$MSG"
    echo "$MSG" >> "$LOG_FILE"
}

log "========================================"
log " Starting Rollback"

if [ -z "$ROLLBACK_TAG" ]; then
    log "No tag specified. Listing available images..."
    echo ""
    docker images "${DOCKER_IMAGE}" --format "table {{.Tag}}\t{{.CreatedAt}}\t{{.Size}}"
    echo ""
    echo "Usage: ./rollback.sh <TAG>"
    echo "Example: ./rollback.sh sha-abc1234"
    exit 1
fi

log " Rolling back to: ${DOCKER_IMAGE}:${ROLLBACK_TAG}"
log "========================================"

# Pull the specific image version
log "[1/3] Pulling image ${DOCKER_IMAGE}:${ROLLBACK_TAG}..."
docker pull "${DOCKER_IMAGE}:${ROLLBACK_TAG}"

# Stop and remove current container
log "[2/3] Stopping current container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Start with the old image
log "[3/3] Starting rollback container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p ${APP_PORT}:3000 \
    -e NODE_ENV=production \
    -e APP_VERSION="${ROLLBACK_TAG}-rollback" \
    "${DOCKER_IMAGE}:${ROLLBACK_TAG}"

sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT}/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    log "✅ Rollback successful! App healthy at HTTP $HTTP_CODE"
else
    log "❌ Rollback health check failed! HTTP $HTTP_CODE"
    exit 1
fi

log "Rollback complete."
