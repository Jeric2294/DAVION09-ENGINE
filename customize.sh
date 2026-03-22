#!/system/bin/sh
SKIPUNZIP=0

# ============================================================
#   GOVERNOR / REFRESH RATE MANAGER
#   by Cirej09Davion + Jeric
# ============================================================

ui_print " "
ui_print "  ⚡ CPU Governor & Thermal Control"
ui_print "  🔒 Per-App Refresh Rate Control"
ui_print "     MediaTek · Nexus UI"
ui_print " "

# ── Detect Root Manager ──────────────────────────────────────
if [ -d /data/adb/apatch ]; then
    ROOT_ENV="APatch"; ROOT_ICON="🩹"
elif [ -d /data/adb/ksu ]; then
    ROOT_ENV="KernelSU"; ROOT_ICON="🌿"
elif [ -d /data/adb/magisk ]; then
    ROOT_ENV="Magisk"; ROOT_ICON="🪄"
elif [ -d /data/adb/sukisu ]; then
    ROOT_ENV="SukiSU"; ROOT_ICON="🌸"
else
    ROOT_ENV="Unknown"; ROOT_ICON="❓"
fi

# ── Device Info ──────────────────────────────────────────────
MODEL=$(getprop ro.product.model)
ANDROID=$(getprop ro.build.version.release)
SDK=$(getprop ro.build.version.sdk)
SOC=$(getprop ro.board.platform)
KERNEL=$(uname -r)
ARCH=$(getprop ro.product.cpu.abi)
SELINUX=$(getenforce 2>/dev/null || echo "Unknown")
DISP_RATE=$(dumpsys display 2>/dev/null | grep -m1 -oE '[0-9]+\.[0-9]+ fps' | head -n1)
[ -z "$DISP_RATE" ] && DISP_RATE=$(dumpsys display 2>/dev/null | grep -m1 "refreshRate" | grep -oE '[0-9]+\.[0-9]+' | head -n1 | sed 's/$/ fps/')
[ -z "$DISP_RATE" ] && DISP_RATE=$(service call SurfaceFlinger 1013 2>/dev/null | grep -oE '[0-9]{2,3}' | head -n1 | sed 's/$/ fps/')
[ -z "$DISP_RATE" ] && DISP_RATE="Unknown"
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_GB=$(( (MEM_TOTAL + 524288) / 1048576 ))

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  📱 DEVICE INFO"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  ${ROOT_ICON} Root Manager  : $ROOT_ENV"
ui_print "  📱 Model        : $MODEL"
ui_print "  🤖 Android      : $ANDROID  (API $SDK)"
ui_print "  🔲 SoC          : $SOC"
ui_print "  🐧 Kernel       : $KERNEL"
ui_print "  🏗  Arch         : $ARCH"
ui_print "  🧠 RAM          : ~${MEM_GB}GB"
ui_print "  🖥  Display Rate : $DISP_RATE"
ui_print "  🔒 SELinux      : $SELINUX"
ui_print " "

# ── CPU Clusters ─────────────────────────────────────────────
ui_print "  ⚙  CPU Clusters:"
for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    [ -d "$policy" ] || continue
    PID=$(basename "$policy")
    GOV=$(cat "$policy/scaling_governor" 2>/dev/null || echo "?")
    MAX=$(cat "$policy/cpuinfo_max_freq"  2>/dev/null || echo "0")
    MHZ=$((MAX / 1000))
    ui_print "     $PID  $GOV @ ${MHZ}MHz"
done
ui_print " "

# ── GPU ──────────────────────────────────────────────────────
if ls /sys/class/devfreq/*mali* >/dev/null 2>&1; then
    MALI_PATH=$(ls -d /sys/class/devfreq/*mali* 2>/dev/null | head -n1)
    GPU_GOV=$(cat "$MALI_PATH/governor" 2>/dev/null || echo "?")
    ui_print "  🎮 GPU          : ARM Mali  ($GPU_GOV)"
elif [ -d /sys/class/kgsl/kgsl-3d0 ]; then
    ui_print "  🎮 GPU          : Qualcomm Adreno"
fi
ui_print " "

# ── Installing ──────────────────────────────────────────────
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  📦 INSTALLING"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$MODPATH/system/etc"
mkdir -p "$MODPATH/vendor/etc"
mkdir -p "$MODPATH/Extras"

# Backup stock system files
ui_print "  📋 Backing up stock system files..."
[ -f "/system/etc/gameprops.json"    ] && cp "/system/etc/gameprops.json"    "$MODPATH/Extras/gameprops_stock.json"    2>/dev/null
[ -f "/vendor/etc/gbe.cfg"           ] && cp "/vendor/etc/gbe.cfg"           "$MODPATH/Extras/gbe_stock.cfg"           2>/dev/null
[ -f "/vendor/etc/qt.cfg"            ] && cp "/vendor/etc/qt.cfg"            "$MODPATH/Extras/qt_stock.cfg"            2>/dev/null
[ -f "/vendor/etc/xgf.cfg"           ] && cp "/vendor/etc/xgf.cfg"           "$MODPATH/Extras/xgf_stock.cfg"           2>/dev/null
[ -f "/vendor/etc/fstb.cfg"          ] && cp "/vendor/etc/fstb.cfg"          "$MODPATH/Extras/fstb_stock.cfg"          2>/dev/null
[ -f "/vendor/etc/power_app_cfg.xml" ] && cp "/vendor/etc/power_app_cfg.xml" "$MODPATH/Extras/power_app_cfg_stock.xml" 2>/dev/null
[ -f "/vendor/etc/powercontable.xml" ] && cp "/vendor/etc/powercontable.xml" "$MODPATH/Extras/powercontable_stock.xml" 2>/dev/null
[ -f "/vendor/etc/powerscntbl.xml"   ] && cp "/vendor/etc/powerscntbl.xml"   "$MODPATH/Extras/powerscntbl_stock.xml"   2>/dev/null
ui_print "  ✅ Stock files backed up"

# Deploy custom engine configs
ui_print "  🔧 Deploying engine configs..."
cp "$MODPATH/Extras/gameprops_custom.json"    "$MODPATH/system/etc/gameprops.json"    2>/dev/null
cp "$MODPATH/Extras/gbe_custom.cfg"           "$MODPATH/vendor/etc/gbe.cfg"           2>/dev/null
cp "$MODPATH/Extras/qt_custom.cfg"            "$MODPATH/vendor/etc/qt.cfg"            2>/dev/null
cp "$MODPATH/Extras/fstb_custom.cfg"          "$MODPATH/vendor/etc/fstb.cfg"          2>/dev/null
cp "$MODPATH/Extras/xgf_custom.cfg"           "$MODPATH/vendor/etc/xgf.cfg"           2>/dev/null
cp "$MODPATH/Extras/powerscntbl_custom.xml"   "$MODPATH/vendor/etc/powerscntbl.xml"   2>/dev/null
cp "$MODPATH/Extras/powercontable_custom.xml" "$MODPATH/vendor/etc/powercontable.xml" 2>/dev/null
cp "$MODPATH/Extras/power_app_cfg_custom.xml" "$MODPATH/vendor/etc/power_app_cfg.xml" 2>/dev/null
ui_print "  ✅ Engine configs deployed"

# Setup config directories
ui_print "  📁 Setting up config directories..."
mkdir -p /sdcard/GovThermal/config
mkdir -p /sdcard/DAVION_ENGINE/config
mkdir -p /sdcard/DAVION_ENGINE/refresh_locks
echo "volt" > /sdcard/GovThermal/config/theme 2>/dev/null
touch /sdcard/DAVION_ENGINE/config/enable_logcat 2>/dev/null
rm -f /sdcard/DAVION_ENGINE/config/enable_dumpsys 2>/dev/null
echo "on"  > /sdcard/DAVION_ENGINE/config/overlay_state 2>/dev/null
ui_print "  ✅ RR detection set to logcat  |  Theme: Volt"

# Game list
GAME_LIST_FILE="/sdcard/DAVION_ENGINE/game_list.txt"
LOG_FILE="/sdcard/GovThermal/GovThermal.log"

if [ ! -f "$GAME_LIST_FILE" ]; then
    ui_print "  📝 Creating game list..."
    cat > "$GAME_LIST_FILE" << 'GAMELIST'
com.miHoYo.GenshinImpact
com.miHoYo.hkrpg
com.HoYoverse.Nap
com.activision.callofduty.shooter
com.garena.game.codm
com.tencent.ig
com.tencent.tmgp.pubgmhd
com.pubg
com.epicgames.fortnite
com.riotgames.league.wildrift
com.mobile.legends
com.supercell.brawlstars
com.supercell.clashofclans
com.supercell.clashroyale
com.roblox.client
com.mojang.minecraftpe
com.ea.gp.fifamobile
com.netease.onmyoji
com.kurogame.wutheringwaves.global
com.bluepoch.m.en.reverse1999
com.proximabeta.nikke
com.YoStarEN.Arknights
com.hypergryph.arknights
com.cygames.umamusume
com.YoStarEN.MahjongSoul
com.netease.idv
com.netease.pes
com.tgc.sky.android
com.axlebolt.standoff2
com.farlightgames.igame.gp
GAMELIST
    chmod 0666 "$GAME_LIST_FILE"
    COUNT=$(wc -l < "$GAME_LIST_FILE")
    ui_print "  ✅ Game list created ($COUNT titles)"
else
    ui_print "  ♻  Existing game list preserved"
fi

touch "$LOG_FILE" 2>/dev/null
chmod 0666 "$LOG_FILE" 2>/dev/null

# Set permissions
ui_print "  🔑 Setting permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
chmod 755 "$MODPATH/busybox"                    2>/dev/null
chmod 755 "$MODPATH/service.sh"                 2>/dev/null
chmod 755 "$MODPATH/post-fs-data.sh"            2>/dev/null
chmod 755 "$MODPATH/logcat_detection/logcat"    2>/dev/null
chmod 755 "$MODPATH/logcat_detection/dumpsys2"  2>/dev/null
find "$MODPATH/script_runner"    -type f -exec chmod 755 {} \; 2>/dev/null
find "$MODPATH/service.d"        -type f -exec chmod 755 {} \; 2>/dev/null
find "$MODPATH/webroot/cgi-bin"  -type f -exec chmod 755 {} \; 2>/dev/null
chmod 755 "$MODPATH/action.sh" 2>/dev/null
ui_print "  ✅ Permissions set"

# Initialize thermal state default
ui_print "  🌡️ Thermal Control — default: ENABLED (safe)"
echo "enabled" > /sdcard/GovThermal/config/thermal_state

# Set default CPU governor to sugov_ext (or best available fallback)
ui_print "  ⚙️  Setting default CPU governor..."
AVAIL_GOVS=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_governors 2>/dev/null \
          || cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null \
          || echo "")
DEFAULT_GOV=""
for g in sugov_ext schedhorizon schedutil_plus uag schedplus schedutil ondemand interactive; do
    case " $AVAIL_GOVS " in
        *" $g "*) DEFAULT_GOV="$g"; break ;;
    esac
done
[ -z "$DEFAULT_GOV" ] && DEFAULT_GOV="schedutil"
# Write to de_cpu_engine config file (primary)
echo "$DEFAULT_GOV" > /sdcard/GovThermal/config/gov_balanced 2>/dev/null
# Write prop for azenith_cpu_engine backward compat
setprop persist.sys.mtkaieng.custom_default_cpu_gov "$DEFAULT_GOV" 2>/dev/null
ui_print "  ✅ Default governor set to: $DEFAULT_GOV"

# Done
ui_print " "
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  ✅ INSTALLATION COMPLETE"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print " "
ui_print "  🌐 Tap OPEN in $ROOT_ENV to launch WebUI"
ui_print "  🔒 Panel 03: Set per-app / universal RR"
ui_print "  ⚡ Panel 01: CPU Governor & Freq"
ui_print "  🌡️ Panel 02: Thermal Status"
ui_print "  💾 Tap SAVE to persist settings"
ui_print "  📄 Logs: /sdcard/GovThermal/"
ui_print " "
ui_print "  ⚡ Reboot your device to activate"
ui_print " "
