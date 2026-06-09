#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo "CHROME DESKTOP UPDATE STARTED: $(date)"
echo "================================================="

echo
echo "[STEP 1] Enable silent printing in Google Chrome..."

DESKTOP_FILE="/home/user/.local/share/applications/google-chrome.desktop"

if [ ! -f "$DESKTOP_FILE" ]; then

echo "[ERROR] Desktop file not found:"
echo "        $DESKTOP_FILE"

exit 1

fi

echo "[INFO] Desktop file found"

echo
echo "[STEP 2] Backup current Chrome launcher configuration..."

cp -f "$DESKTOP_FILE" "${DESKTOP_FILE}.bak"

echo "[INFO] Backup created:"
echo "       ${DESKTOP_FILE}.bak"

echo
echo "[STEP 3] Configure Chrome kiosk printing and certificate bypass..."

sed -i 's|^Exec=/usr/bin/google-chrome.*|Exec=/usr/bin/google-chrome --kiosk-printing --ignore-certificate-errors %U|' "$DESKTOP_FILE"

echo
echo "[STEP 4] Verifying configuration..."

if grep -q -- "--kiosk-printing --ignore-certificate-errors" "$DESKTOP_FILE"; then

echo "[INFO] Silent printing enabled successfully"
echo "[INFO] Certificate warnings will be ignored"

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
