#!/system/bin/sh
# Davion Engine — App Icon CGI
# Usage: GET /cgi-bin/icon.sh?pkg=com.example.app

# Parse package name from QUERY_STRING
PKG=$(echo "$QUERY_STRING" | sed 's/.*[?&]pkg=//;s/&.*//' | tr -cd 'a-zA-Z0-9._-')
if [ -z "$PKG" ]; then
  echo "Content-Type: text/plain"
  echo ""
  echo "missing pkg"
  exit 0
fi

# Get APK path (handle split APKs too — take first base APK)
APK=$(pm path "$PKG" 2>/dev/null | grep 'base\|apk' | head -1 | sed 's/package://;s/^ //;s/ $//' | tr -d '\r\n')
if [ -z "$APK" ]; then
  APK=$(pm path "$PKG" 2>/dev/null | head -1 | sed 's/package://;s/^ //;s/ $//' | tr -d '\r\n')
fi
if [ -z "$APK" ] || [ ! -f "$APK" ]; then
  echo "Content-Type: text/plain"
  echo ""
  echo "apk not found"
  exit 0
fi

# Try icon candidates in priority order (highest-res first)
for CANDIDATE in \
  "res/mipmap-xxxhdpi-v4/ic_launcher.png" \
  "res/mipmap-xxhdpi-v4/ic_launcher.png" \
  "res/mipmap-xhdpi-v4/ic_launcher.png" \
  "res/mipmap-hdpi-v4/ic_launcher.png" \
  "res/mipmap-mdpi-v4/ic_launcher.png" \
  "res/mipmap-xxxhdpi/ic_launcher.png" \
  "res/mipmap-xxhdpi/ic_launcher.png" \
  "res/mipmap-xhdpi/ic_launcher.png" \
  "res/mipmap-hdpi/ic_launcher.png" \
  "res/mipmap-mdpi/ic_launcher.png" \
  "res/drawable-xxxhdpi/ic_launcher.png" \
  "res/drawable-xxhdpi/ic_launcher.png" \
  "res/drawable-xhdpi/ic_launcher.png" \
  "res/drawable-hdpi/ic_launcher.png" \
  "res/drawable-mdpi/ic_launcher.png"; do
  if unzip -l "$APK" 2>/dev/null | grep -qF "$CANDIDATE"; then
    echo "Content-Type: image/png"
    echo "Cache-Control: max-age=86400"
    echo "Access-Control-Allow-Origin: *"
    printf '\r\n'
    unzip -p "$APK" "$CANDIDATE" 2>/dev/null
    exit 0
  fi
done

# Fallback: find any png with launcher/icon/logo in name
FOUND=$(unzip -l "$APK" 2>/dev/null \
  | grep -oE 'res/(mipmap|drawable)[^[:space:]]*\.png' \
  | grep -iE 'launcher|ic_app|icon|logo' \
  | grep -v 'night\|round\|foreground\|background\|monochrome' \
  | sort -t'-' -k2 -r \
  | head -1)
if [ -n "$FOUND" ]; then
  echo "Content-Type: image/png"
  echo "Cache-Control: max-age=86400"
  echo "Access-Control-Allow-Origin: *"
  printf '\r\n'
  unzip -p "$APK" "$FOUND" 2>/dev/null
  exit 0
fi

# Nothing found
echo "Content-Type: text/plain"
echo ""
echo "icon not found"
