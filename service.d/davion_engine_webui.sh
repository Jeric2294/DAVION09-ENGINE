#!/system/bin/sh

MODDIR=/data/adb/modules/GovThermal
LOG="/data/media/0/DAVION_ENGINE/webui.log"

mkdir -p "/data/media/0/DAVION_ENGINE"
chmod 755 "$MODDIR/busybox"

pkill -f "httpd.*8080" 2>/dev/null
sleep 1

echo "$(date '+%T') Starting httpd on :8080..." >> "$LOG"

"$MODDIR/busybox" httpd \
    -p 8080 \
    -h "$MODDIR/webroot" \
    -c "$MODDIR/httpd.conf" \
    >>"$LOG" 2>&1

echo "$(date '+%T') httpd exited (rc=$?)" >> "$LOG"
