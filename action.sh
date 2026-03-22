#!/system/bin/sh
MODDIR=/data/adb/modules/GovThermal
WEBUI_URL="http://127.0.0.1:8080"
LOG="$MODDIR/httpd_action.log"
PIDFILE="$MODDIR/httpd.pid"
BB="$MODDIR/busybox"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

log "=== ACTION START ==="

pkill -f "httpd.*8080" 2>/dev/null
pkill -f "busybox.*8080" 2>/dev/null
sleep 1

log "Starting httpd..."
nohup "$BB" httpd -p 8080 \
    -h "$MODDIR/webroot" \
    -c "$MODDIR/httpd.conf" \
    </dev/null >>"$LOG" 2>&1 &
PID=$!
echo $PID > "$PIDFILE"
sleep 2

if kill -0 $PID 2>/dev/null; then
    log "httpd running PID=$PID"
else
    log "httpd died, trying without conf..."
    "$BB" httpd -p 8080 -h "$MODDIR/webroot" >>"$LOG" 2>&1 &
    echo $! > "$PIDFILE"
    sleep 1
fi

log "Opening: $WEBUI_URL"
am start -a android.intent.action.VIEW -d "$WEBUI_URL" --activity-clear-top >/dev/null 2>&1 \
|| am start -a android.intent.action.VIEW -d "$WEBUI_URL" >/dev/null 2>&1
log "=== DONE ==="
