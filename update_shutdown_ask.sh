#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo "UPDATE SHUTDOWN-ASK STARTED: $(date)"
echo "================================================="

TARGET="/usr/local/bin/shutdown-ask"
URL="https://raw.githubusercontent.com/momoxapps/lej/refs/heads/main/linux-power-panel.py"

echo
echo "[STEP 1] Checking existing installation"

if [ -f "$TARGET" ]; then

    echo "[INFO] Existing shutdown-ask found"

    echo
    echo "[STEP 2] Creating backup"

    cp -f "$TARGET" "${TARGET}.bak"

    echo "[INFO] Backup created:"
    echo "       ${TARGET}.bak"

    rm -f "$TARGET"

else

    echo "[INFO] No previous installation found"

fi

echo
echo "[STEP 3] Downloading latest version"

wget -qO- "$URL" > "$TARGET"

echo "[INFO] Download completed"

echo
echo "[STEP 4] Setting executable permissions"

chmod +x "$TARGET"

echo "[INFO] Permissions updated"

echo
echo "[STEP 5] Verifying installation"

if [ -f "$TARGET" ]; then
    echo "[INFO] Installation successful"
    ls -l "$TARGET"
else
    echo "[ERROR] Installation failed"
    exit 1
fi

echo
echo "================================================="
echo "UPDATE SHUTDOWN-ASK COMPLETED: $(date)"
echo "================================================="
