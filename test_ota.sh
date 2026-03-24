#!/system/bin/sh
# ============================================================
#  DAVION ENGINE — OTA Diagnostic Test
#  Tests GitHub connectivity and file availability
# ============================================================

MODID="GovThermal"
MODDIR="/data/adb/modules/$MODID"
BB="$MODDIR/busybox"

GITHUB_USER="Jeric2294"
GITHUB_REPO="DAVION09-ENGINE"
BRANCH="master"
RAW="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DAVION ENGINE — OTA Diagnostic Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Check if busybox exists
echo "TEST 1: Checking Busybox..."
if [ ! -f "$BB" ]; then
    echo "  ✗ FAIL: Busybox not found at $BB"
    echo ""
    echo "Fix: Make sure DAVION ENGINE module is installed"
    exit 1
fi

if ! "$BB" --help >/dev/null 2>&1; then
    echo "  ✗ FAIL: Busybox not executable"
    echo ""
    echo "Fix: Run this command:"
    echo "  chmod 755 $BB"
    exit 1
fi

BB_VERSION=$("$BB" | head -1)
echo "  ✔ PASS: $BB_VERSION"
echo ""

# Test 2: Check internet connectivity
echo "TEST 2: Checking Internet Connection..."
if ! "$BB" wget -q --timeout=5 -O /dev/null "https://1.1.1.1" 2>/dev/null; then
    echo "  ✗ FAIL: No internet connection"
    echo ""
    echo "Fix: Enable WiFi or mobile data"
    exit 1
fi
echo "  ✔ PASS: Internet connected"
echo ""

# Test 3: Check DNS resolution
echo "TEST 3: Checking DNS Resolution..."
if ! "$BB" wget -q --timeout=5 -O /dev/null "https://github.com" 2>/dev/null; then
    echo "  ✗ FAIL: Cannot reach GitHub"
    echo ""
    echo "Possible issues:"
    echo "  • DNS not working"
    echo "  • GitHub blocked by ISP/firewall"
    echo "  • Need VPN"
    exit 1
fi
echo "  ✔ PASS: GitHub reachable"
echo ""

# Test 4: Check if repo exists
echo "TEST 4: Checking GitHub Repository..."
TEST_URL="$RAW/README.md"
echo "  Testing URL: $TEST_URL"

if "$BB" wget -q --timeout=10 -O /tmp/davion_test.txt "$TEST_URL" 2>/tmp/davion_error.log; then
    if [ -s /tmp/davion_test.txt ]; then
        echo "  ✔ PASS: Repository accessible"
        echo ""
        echo "  Preview of README.md:"
        echo "  ────────────────────────────────────────"
        head -3 /tmp/davion_test.txt | sed 's/^/  /'
        echo "  ────────────────────────────────────────"
        rm -f /tmp/davion_test.txt
    else
        echo "  ✗ FAIL: File downloaded but empty"
        echo ""
        echo "  This means repo exists but README.md is empty"
    fi
else
    ERROR=$(cat /tmp/davion_error.log 2>/dev/null)
    echo "  ✗ FAIL: Cannot access repository"
    echo ""
    echo "  Full URL: $TEST_URL"
    echo "  Error: $ERROR"
    echo ""
    echo "Possible fixes:"
    echo "  1. Check if repo exists: https://github.com/$GITHUB_USER/$GITHUB_REPO"
    echo "  2. Make sure repo is PUBLIC (not private)"
    echo "  3. Verify branch name is '$BRANCH' (check on GitHub)"
    echo "  4. Ensure files are pushed to GitHub"
    rm -f /tmp/davion_error.log
    exit 1
fi
echo ""

# Test 5: Check critical module files
echo "TEST 5: Checking Module Files Availability..."
CRITICAL_FILES="module.prop action.sh service.sh"
failed=0

for file in $CRITICAL_FILES; do
    url="$RAW/$file"
    echo "  Testing: $file"
    
    if "$BB" wget -q --timeout=10 -O /tmp/davion_test_file "$url" 2>/tmp/davion_file_error.log; then
        if [ -s /tmp/davion_test_file ]; then
            size=$(wc -c < /tmp/davion_test_file)
            echo "    ✔ Available (${size} bytes)"
            rm -f /tmp/davion_test_file
        else
            echo "    ✗ File exists but empty"
            failed=$((failed + 1))
        fi
    else
        echo "    ✗ Not found at: $url"
        failed=$((failed + 1))
    fi
done
rm -f /tmp/davion_file_error.log

echo ""
if [ "$failed" -gt 0 ]; then
    echo "  ✗ FAIL: $failed critical file(s) missing"
    echo ""
    echo "Fix: Push missing files to GitHub repo"
    exit 1
fi
echo "  ✔ PASS: All critical files available"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✔ ALL TESTS PASSED!"
echo ""
echo "  Your OTA setup is working correctly."
echo "  Repository: github.com/$GITHUB_USER/$GITHUB_REPO"
echo "  Branch: $BRANCH"
echo ""
echo "  You can now run action.sh to update your module."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
