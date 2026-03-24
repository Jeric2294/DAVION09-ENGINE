#!/system/bin/sh
echo "Content-Type: text/plain"
echo ""
echo "CGI_OK"
echo "USER=$(id)"
echo "CMD_TEST=$(echo hello)"
