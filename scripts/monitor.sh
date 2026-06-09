#!/bin/bash
# ============================================================
#  scripts/monitor.sh
#  Basic health monitoring and logging for the application.
#  Run as a cron job: */5 * * * * /opt/cicd-app/scripts/monitor.sh
# ============================================================

# ---- Configuration ----
APP_URL="http://localhost:3000"
CONTAINER_NAME="cicd-demo-app"
LOG_FILE="/opt/cicd-app/logs/monitor.log"
ALERT_LOG="/opt/cicd-app/logs/alerts.log"

# ---- Colors for terminal ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# ---- Log function ----
log() {
    local LEVEL="$1"
    local MSG="$2"
    local TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
    local LINE="[$TIMESTAMP] [$LEVEL] $MSG"
    echo -e "$LINE"
    mkdir -p "$(dirname $LOG_FILE)"
    echo "$LINE" >> "$LOG_FILE"
    if [ "$LEVEL" == "ALERT" ]; then
        echo "$LINE" >> "$ALERT_LOG"
    fi
}

echo "========================================"
echo " Health Monitor - $(date)"
echo "========================================"

# ---- 1. Container status ----
echo ""
echo "--- Container Status ---"
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_NAME 2>/dev/null || echo "not_found")
if [ "$CONTAINER_STATUS" == "running" ]; then
    log "INFO" "Container '$CONTAINER_NAME': ${GREEN}running${NC}"
else
    log "ALERT" "Container '$CONTAINER_NAME' is NOT running! Status: $CONTAINER_STATUS"
fi

# Container uptime
STARTED_AT=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER_NAME 2>/dev/null || echo "N/A")
log "INFO" "Container started: $STARTED_AT"

# ---- 2. HTTP health check ----
echo ""
echo "--- HTTP Health Check ---"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${APP_URL}/health" 2>/dev/null || echo "000")
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 5 "${APP_URL}/health" 2>/dev/null || echo "N/A")

if [ "$HTTP_CODE" == "200" ]; then
    log "INFO" "HTTP health check: ${GREEN}PASSED${NC} (HTTP $HTTP_CODE, ${RESPONSE_TIME}s)"
else
    log "ALERT" "HTTP health check FAILED! HTTP code: $HTTP_CODE"
fi

# ---- 3. Application metrics ----
echo ""
echo "--- App Metrics ---"
HEALTH_DATA=$(curl -s --max-time 5 "${APP_URL}/health" 2>/dev/null || echo "{}")
APP_VERSION=$(echo $HEALTH_DATA | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "N/A")
APP_UPTIME=$(echo $HEALTH_DATA | grep -o '"uptime":[0-9.]*' | cut -d':' -f2 || echo "N/A")
log "INFO" "App version : $APP_VERSION"
log "INFO" "App uptime  : ${APP_UPTIME}s"

# ---- 4. System resources ----
echo ""
echo "--- System Resources ---"

# CPU Usage
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'.' -f1 2>/dev/null || echo "N/A")
CPU_USED=$((100 - ${CPU_IDLE:-0}))
log "INFO" "CPU usage   : ${CPU_USED}%"

# Memory Usage
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_USED=$(free -m | awk '/^Mem:/{print $3}')
MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))
log "INFO" "Memory      : ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PERCENT}%)"
if [ $MEM_PERCENT -gt 85 ]; then
    log "ALERT" "High memory usage: ${MEM_PERCENT}%"
fi

# Disk Usage
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
log "INFO" "Disk usage  : ${DISK_USAGE}%"
if [ "$DISK_USAGE" -gt 80 ] 2>/dev/null; then
    log "ALERT" "High disk usage: ${DISK_USAGE}%"
fi

# ---- 5. Docker stats ----
echo ""
echo "--- Container Stats ---"
if [ "$CONTAINER_STATUS" == "running" ]; then
    docker stats --no-stream --format \
        "CPU: {{.CPUPerc}} | MEM: {{.MemUsage}} | NET: {{.NetIO}}" \
        $CONTAINER_NAME 2>/dev/null || log "WARN" "Could not get container stats"
fi

# ---- 6. Recent logs (last 5 lines) ----
echo ""
echo "--- Recent App Logs ---"
docker logs --tail=5 $CONTAINER_NAME 2>/dev/null || echo "(no logs available)"

echo ""
echo "========================================"
echo " Monitor run complete: $(date)"
echo " Log file: $LOG_FILE"
echo "========================================"
