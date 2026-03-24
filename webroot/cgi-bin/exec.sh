#!/system/bin/sh
# Davion Engine CGI exec bridge

echo "Content-Type: text/plain"
echo "Cache-Control: no-store"
echo ""

[ "$REQUEST_METHOD" = "OPTIONS" ] && exit 0

# Read POST body
CMD=$(cat 2>/dev/null)
[ -z "$CMD" ] && exit 0

# Run command directly (httpd already runs as root)
# Suppress stderr to avoid polluting response
sh -c "$CMD" 2>/dev/null
