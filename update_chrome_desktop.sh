#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo "CHROME DESKTOP UPDATE STARTED: $(date)"
echo "================================================="

echo
echo "[STEP 1] Checking Chrome desktop entry..."

DESKTOP_FILE="/home/user/.local/share/applications/google-chrome.desktop"

if [ ! -f "$DESKTOP_FILE" ]; then

echo "[ERROR] Desktop file not found:"
echo "        $DESKTOP_FILE"

exit 1

fi

echo "[INFO] Desktop file found"

echo
echo "[STEP 2] Creating backup..."

cp -f "$DESKTOP_FILE" "${DESKTOP_FILE}.bak"

echo "[INFO] Backup created:"
echo "       ${DESKTOP_FILE}.bak"

echo
echo "[STEP 3] Updating Chrome launch options..."

sed -i 
's|^Exec=/usr/bin/google-chrome.*|Exec=/usr/bin/google-chrome --kiosk-printing --ignore-certificate-errors %U|' 
"$DESKTOP_FILE"

echo
echo "[STEP 4] Verifying configuration..."

if grep -q -- "--kiosk-printing" "$DESKTOP_FILE"; then

echo "[INFO] Chrome desktop entry updated successfully"

else

echo "[ERROR] Chrome desktop modification failed"

exit 1

fi

echo
echo "[STEP 5] Current Exec line"

grep '^Exec=' "$DESKTOP_FILE" || true

echo
echo "================================================="
echo "CHROME DESKTOP UPDATE COMPLETED: $(date)"
echo "================================================="
