#!/system/bin/sh
MODDIR="/data/adb/modules/GovThermal"
CFG_DIR="/sdcard/GovThermal/config"

# Early thermal disable (before userspace thermal HAL starts)
# /sdcard not mounted yet here — read from /data/media/0 directly
THERMAL_STATE_FILE="/data/media/0/GovThermal/config/thermal_state"

if [ "$(cat "$THERMAL_STATE_FILE" 2>/dev/null | tr -d '[:space:]')" = "disabled" ]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        [ -f "$zone/mode" ] || continue
        chmod 644 "$zone/mode" 2>/dev/null
        echo "disabled" > "$zone/mode" 2>/dev/null
        chmod 444 "$zone/mode" 2>/dev/null
    done
    if [ -f /proc/driver/thermal/tzcpu ]; then
        t="125"
        nc="0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler"
        echo "1 ${t}000 0 mtktscpu-sysrst $nc 200"      > /proc/driver/thermal/tzcpu     2>/dev/null
        echo "1 ${t}000 0 mtktspmic-sysrst $nc 1000"    > /proc/driver/thermal/tzpmic    2>/dev/null
        echo "1 ${t}000 0 mtktsbattery-sysrst $nc 1000" > /proc/driver/thermal/tzbattery 2>/dev/null
        echo "1 ${t}000 0 mtktscharger-sysrst $nc 2000" > /proc/driver/thermal/tzcharger 2>/dev/null
        echo "1 ${t}000 0 mtktswmt-sysrst $nc 1000"     > /proc/driver/thermal/tzwmt     2>/dev/null
    fi
    if [ -f /sys/class/thermal/thermal_zone0/thm_enable ]; then
        chmod 644 /sys/class/thermal/thermal_zone0/thm_enable 2>/dev/null
        echo 0 > /sys/class/thermal/thermal_zone0/thm_enable 2>/dev/null
        chmod 444 /sys/class/thermal/thermal_zone0/thm_enable 2>/dev/null
    fi
fi

# Permissions — ONLY our own module files, never touch DAVION_ENGINE
set_perm_recursive "$MODDIR" 0 0 0755 0644
chmod 755 "$MODDIR/busybox"                                2>/dev/null
chmod 755 "$MODDIR/DAVION_ENGINE/AI_MODE/azenith_cpu_engine"     2>/dev/null
find "$MODDIR/script_runner" -type f -exec chmod 755 {} \; 2>/dev/null
find "$MODDIR/DAVION_ENGINE/AI_MODE" -type f -exec chmod 755 {} \; 2>/dev/null

# ── Headset/OTG Detection Fix (MTK) ───────────────────────────
# Ensure extcon nodes are readable for detection scripts
for i in 0 1 2 3 4 5; do
    [ -d "/sys/class/extcon/extcon$i" ] && chmod 644 "/sys/class/extcon/extcon$i/state" 2>/dev/null
done
for n in usb-otg mtk-usb mtk-otg mtk-vbus mtk-id typec; do
    [ -d "/sys/class/extcon/$n" ] && chmod 644 "/sys/class/extcon/$n/state" 2>/dev/null
done
# ─────────────────────────────────────────────────────────────

# ── StormGuard post-fs-data hook ──────────────────────────────
SG_HOOK="$MODDIR/stormguard_hook.sh_post"
SG_STATE_FILE="/data/media/0/GovThermal/config/stormguard_state"
if [ "$(cat "$SG_STATE_FILE" 2>/dev/null | tr -d '[:space:]')" = "applied" ] && [ -x "$SG_HOOK" ]; then
    sh "$SG_HOOK"
fi
# ─────────────────────────────────────────────────────────────
