#!/system/bin/sh
# ============================================================
#  DAVION09 ENGINE — Action Handler
#  Author: Jeric Aparicio
#  Action = Fetch latest files from GitHub
# ============================================================

MODID="GovThermal"
MODDIR="/data/adb/modules/$MODID"
TMP="/data/local/tmp/davion_ota"
LOG="$MODDIR/ota.log"
BB="$MODDIR/busybox"

GITHUB_USER="Jeric2294"
GITHUB_REPO="DAVION09-ENGINE"
BRANCH="master"
RAW="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH"

# Create log directory if needed
mkdir -p "$(dirname "$LOG")" 2>/dev/null

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

# ui_print wrapper - works both in installer and standalone
ui_print() {
    if [ -n "$OUTFD" ]; then
        # Magisk installer context
        echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD
    else
        # Standalone script - just echo
        echo "$1"
        log "$1"
    fi
}

# === Files to update — URLs built from RAW automatically ===
FILES="
action.sh
service.sh
post-fs-data.sh
customize.sh
system.prop
module.prop
service.d/davion_engine_webui.sh
script_runner/refresh_rate_locker
script_runner/rr_guard
script_runner/idle60_daemon
script_runner/sf_controller
script_runner/thermal_watchdog
script_runner/thermal_toggle
script_runner/battery_guard
script_runner/headset_daemon
script_runner/ai_thermal_predict
script_runner/ai_adaptive_freq
script_runner/ai_app_classifier
script_runner/encore_app_daemon
script_runner/per_app_daemon
script_runner/hot_reload_daemon
script_runner/de_toast
script_runner/cool_mode
script_runner/global
script_runner/display_mode
script_runner/davion_engine_eem_boot
script_runner/davion_engine_manual
logcat_detection/logcat
logcat_detection/dumpsys2
webroot/index.html
webroot/style.css
webroot/script.js
webroot/config.json
webroot/cgi-bin/exec.sh
webroot/cgi-bin/icon.sh
webroot/cgi-bin/test.sh
DAVION_ENGINE/AI_MODE/azenith_cpu_engine
DAVION_ENGINE/AI_MODE/cpu_governor_control
DAVION_ENGINE/AI_MODE/de_cpu_engine
"

# ── HEADER ───────────────────────────────────────────────────
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  DAVION09 ENGINE — OTA Update"
ui_print "  github.com/$GITHUB_USER/$GITHUB_REPO"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "=== ACTION START ==="

# ── CHECK BUSYBOX ────────────────────────────────────────────
if [ ! -f "$BB" ]; then
    ui_print "✗ Busybox not found at: $BB"
    ui_print "  Module may not be installed correctly"
    log "ERROR: Busybox missing"
    exit 1
fi

if ! "$BB" --help >/dev/null 2>&1; then
    ui_print "✗ Busybox exists but not executable"
    ui_print "  Trying to fix permissions..."
    chmod 755 "$BB" 2>/dev/null
    if ! "$BB" --help >/dev/null 2>&1; then
        ui_print "✗ Still can't execute busybox"
        log "ERROR: Busybox not executable"
        exit 1
    fi
    ui_print "✔ Permissions fixed"
fi

# Log diagnostic info
log "Busybox: $BB"
log "Module: $MODDIR"
log "Repo: $GITHUB_USER/$GITHUB_REPO ($BRANCH)"

# ── CHECK NETWORK ────────────────────────────────────────────
ui_print ""
ui_print "⚙ Checking network..."
if ! "$BB" wget -q --timeout=5 -O /dev/null "https://1.1.1.1" 2>/dev/null; then
    ui_print "✗ No internet connection!"
    log "ERROR: No network"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
ui_print "✔ Network OK"

# ── CHECK GITHUB REPO ACCESS ─────────────────────────────────
ui_print "⚙ Checking GitHub repo access..."
TEST_URL="$RAW/module.prop"
if ! "$BB" wget -q --timeout=10 -O /dev/null "$TEST_URL" 2>/dev/null; then
    ui_print "✗ Cannot access GitHub repo!"
    ui_print "  Repo: $GITHUB_USER/$GITHUB_REPO"
    ui_print "  Branch: $BRANCH"
    ui_print ""
    ui_print "Possible issues:"
    ui_print "  • Repo is private or doesn't exist"
    ui_print "  • Branch name is wrong"
    ui_print "  • Files not pushed to GitHub"
    log "ERROR: Cannot access $TEST_URL"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
ui_print "✔ GitHub repo accessible"

# ── FETCH FILES ──────────────────────────────────────────────
ui_print "↓ Downloading latest files..."
ui_print ""
mkdir -p "$TMP"
updated=0
failed=0

for rel_path in $FILES; do
    [ -z "$rel_path" ] && continue

    url="$RAW/$rel_path"
    target="$MODDIR/$rel_path"
    mkdir -p "$(dirname "$target")" 2>/dev/null

    # Show current file being downloaded
    ui_print "  → $rel_path"
    
    if "$BB" wget -q --timeout=15 \
        -O "$TMP/tmpfile" "$url" 2>"$TMP/error.log" \
        && [ -s "$TMP/tmpfile" ]; then
        cp "$TMP/tmpfile" "$target"
        chmod 755 "$target" 2>/dev/null
        log "✔ $rel_path"
        updated=$((updated + 1))
    else
        ERROR_MSG=$(cat "$TMP/error.log" 2>/dev/null)
        ui_print "    ✗ FAILED"
        log "✗ FAILED: $rel_path (URL: $url)"
        [ -n "$ERROR_MSG" ] && log "  Error: $ERROR_MSG"
        failed=$((failed + 1))
    fi
done

# ── FIX PERMISSIONS ──────────────────────────────────────────
find "$MODDIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find "$MODDIR/script_runner" -type f -exec chmod +x {} \; 2>/dev/null
find "$MODDIR/logcat_detection" -type f -exec chmod +x {} \; 2>/dev/null
find "$MODDIR/webroot/cgi-bin" -type f -exec chmod +x {} \; 2>/dev/null
chmod +x "$MODDIR/busybox" 2>/dev/null

# ── APPLY CHANGES ────────────────────────────────────────────
if [ "$updated" -gt 0 ]; then
    ui_print "⚙ Applying changes..."
    sh "$MODDIR/script_runner/de_reload" >>"$LOG" 2>&1
    ui_print "✔ Changes applied successfully"
    log "de_reload executed"
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
    [ "$failed" -gt 0 ] && ui_print "  Check log: $LOG"
else
    if [ "$failed" -gt 0 ]; then
        ui_print "  ✗ Update failed!"
        ui_print "  All $failed file(s) failed to download"
        ui_print ""
        ui_print "  Check log: $LOG"
        ui_print ""
        ui_print "  Possible fixes:"
        ui_print "  • Verify GitHub repo exists and is public"
        ui_print "  • Push files to GitHub first"
        ui_print "  • Check internet connection"
    else
        ui_print "  ✔ Already up to date!"
    fi
fi
ui_print "  No reboot needed."
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "=== ACTION DONE (updated=$updated failed=$failed) ==="

# Exit with error code if any files failed
[ "$failed" -gt 0 ] && exit 1
exit 0
