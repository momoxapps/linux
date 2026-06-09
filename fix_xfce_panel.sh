#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo "XFCE PANEL FIX STARTED: $(date)"
echo "================================================="

XFCONF_FILE="/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
BACKUP_FILE="${XFCONF_FILE}.bak"

echo
echo "[STEP 1] Checking XFCE panel configuration"

if [ ! -f "$XFCONF_FILE" ]; then
    echo "[ERROR] XFCE panel config not found:"
    echo "        $XFCONF_FILE"
    exit 1
fi

echo "[INFO] Configuration file found"

echo
echo "[STEP 2] Creating backup"

cp -f "$XFCONF_FILE" "$BACKUP_FILE"

echo "[INFO] Backup created:"
echo "       $BACKUP_FILE"

echo
echo "[STEP 3] Downloading new configuration"

wget -O "$XFCONF_FILE" \
https://raw.githubusercontent.com/momoxapps/lej/refs/heads/main/xfce4-panel.xml

echo "[INFO] New XFCE panel configuration installed"

echo
echo "[STEP 4] Restarting XFCE panel"

pkill xfce4-panel 2>/dev/null || true

su - user -c 'DISPLAY=:0 xfce4-panel &' >/dev/null 2>&1 &

echo "[INFO] XFCE panel restarted"

echo
echo "================================================="
echo "XFCE PANEL FIX COMPLETED: $(date)"
echo "================================================="
