#!/system/bin/sh
# ============================================================
#  DAVION09 ENGINE — Action Handler
#  Author: Jeric Aparicio
#  Action = Fetch latest files from GitHub via manifest.txt
# ============================================================

MODID="GovThermal"
MODDIR="/data/adb/modules/$MODID"
TMP="/data/local/tmp/davion_ota"
LOG="$MODDIR/ota.log"
BB="$MODDIR/busybox"

GITHUB_USER="Jeric2294"
GITHUB_REPO="DAVION09-ENGINE"
BRANCH="main"

MANIFEST_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/manifest.txt"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

# ── HEADER ───────────────────────────────────────────────────
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  DAVION09 ENGINE — OTA Update"
ui_print "  github.com/$GITHUB_USER/$GITHUB_REPO"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "=== ACTION START ==="

# ── CHECK NETWORK ────────────────────────────────────────────
ui_print ""
ui_print "⚙ Checking network..."
if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    ui_print "✗ No internet connection!"
    ui_print "  Connect to WiFi or Mobile Data first."
    log "ERROR: No network"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
ui_print "✔ Network OK"

# ── DOWNLOAD MANIFEST ────────────────────────────────────────
ui_print "⚙ Fetching manifest from GitHub..."
mkdir -p "$TMP"
log "Fetching: $MANIFEST_URL"

"$BB" wget -q --timeout=10 --tries=3 \
    -O "$TMP/manifest.txt" "$MANIFEST_URL" 2>/dev/null

if [ ! -s "$TMP/manifest.txt" ]; then
    ui_print "✗ Cannot reach GitHub."
    ui_print "  Check internet and try again."
    log "ERROR: manifest download failed"
    rm -rf "$TMP"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
ui_print "✔ Manifest fetched"
log "Manifest downloaded OK"

# ── FETCH EACH FILE ──────────────────────────────────────────
ui_print "↓ Downloading latest files..."
updated=0
failed=0

while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac

    rel_path=$(echo "$line" | cut -d' ' -f1)
    url=$(echo "$line"      | cut -d' ' -f2-)
    [ -z "$rel_path" ] || [ -z "$url" ] && continue

    target="$MODDIR/$rel_path"
    mkdir -p "$(dirname "$target")" 2>/dev/null

    if "$BB" wget -q --timeout=15 --tries=3 \
        -O "$TMP/tmpfile" "$url" 2>/dev/null \
        && [ -s "$TMP/tmpfile" ]; then
        cp "$TMP/tmpfile" "$target"
        chmod 755 "$target" 2>/dev/null
        log "✔ $rel_path"
        updated=$((updated + 1))
    else
        log "✗ FAILED: $rel_path"
        failed=$((failed + 1))
    fi

done < "$TMP/manifest.txt"

# ── FIX PERMISSIONS ──────────────────────────────────────────
find "$MODDIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find "$MODDIR/script_runner" -type f -exec chmod +x {} \; 2>/dev/null
find "$MODDIR/logcat_detection" -type f -exec chmod +x {} \; 2>/dev/null
find "$MODDIR/webroot/cgi-bin" -type f -exec chmod +x {} \; 2>/dev/null
chmod +x "$MODDIR/busybox" 2>/dev/null

# ── RESTART WEBUI ────────────────────────────────────────────
if [ "$updated" -gt 0 ]; then
    ui_print "⚙ Restarting WebUI..."
    pkill -f "httpd.*8080" 2>/dev/null
    pkill -f "busybox.*8080" 2>/dev/null
    sleep 1
    "$BB" httpd \
        -p 8080 \
        -h "$MODDIR/webroot" \
        -c "$MODDIR/httpd.conf" \
        >>"$LOG" 2>&1 &
    sleep 1
    ui_print "✔ WebUI restarted"
    log "httpd restarted"
fi

# ── CLEANUP ──────────────────────────────────────────────────
rm -rf "$TMP"
log "Cleanup done"

# ── DONE ─────────────────────────────────────────────────────
ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$updated" -gt 0 ]; then
    ui_print "  ✔ Updated $updated file(s)!"
    [ "$failed" -gt 0 ] && ui_print "  ⚠ Failed: $failed file(s)"
else
    ui_print "  ✔ No changes — already latest!"
fi
ui_print "  No reboot needed."
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "=== ACTION DONE (updated=$updated failed=$failed) ==="
exit 0
