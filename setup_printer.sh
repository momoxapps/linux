#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo "PRINTER SETUP STARTED: $(date)"
echo "================================================="

############################################
# 1. REMOVE EXISTING PRINTERS
############################################

echo
echo "[STEP 1] Removing existing printers..."

PRINTERS=$(lpstat -p 2>/dev/null | awk '{print $2}' || true)

if [ -z "$PRINTERS" ]; then
    echo "[INFO] No existing printers found"
else
    echo "$PRINTERS" | while read -r printer; do
        if [ -n "$printer" ]; then
            echo "[INFO] Removing printer: $printer"
            lpadmin -x "$printer" || true
        fi
    done
fi

############################################
# 2. RESET CUPS CONFIG
############################################

echo
echo "[STEP 2] Resetting CUPS configuration..."

for file in /etc/cups/printers.conf /etc/cups/classes.conf; do

    if [ -f "$file" ]; then

        cp -f "$file" "${file}.bak"

        echo "[INFO] Backup created:"
        echo "       ${file}.bak"

        rm -f "$file"
    fi

done

systemctl restart cups

############################################
# 3. CLEAN CHROME PRINT DATA
############################################

echo
echo "[STEP 3] Cleaning Chrome print data..."

TARGET_USER="${SUDO_USER:-user}"
USER_HOME=$(eval echo "~$TARGET_USER")

CHROME_PROFILE="$USER_HOME/.config/google-chrome/Default"

if [ -d "$CHROME_PROFILE" ]; then

    echo "[INFO] Cleaning Chrome profile for user: $TARGET_USER"

    rm -rf "$CHROME_PROFILE/Printer"* 2>/dev/null || true
    rm -rf "$CHROME_PROFILE/printing"* 2>/dev/null || true

else

    echo "[INFO] Chrome profile not found"

fi

pkill -u "$TARGET_USER" chrome 2>/dev/null || true

############################################
# 4. DISABLE NETWORK PRINT DISCOVERY
############################################

echo
echo "[STEP 4] Disabling network print discovery..."

systemctl stop cups-browsed 2>/dev/null || true
systemctl mask cups-browsed 2>/dev/null || true

systemctl stop avahi-daemon.socket 2>/dev/null || true
systemctl mask avahi-daemon.socket 2>/dev/null || true

systemctl stop avahi-daemon 2>/dev/null || true
systemctl mask avahi-daemon.service 2>/dev/null || true

systemctl daemon-reload 2>/dev/null || true

############################################
# 5. PATCH CUPSD.CONF
############################################

echo
echo "[STEP 5] Updating cupsd.conf..."

CUPS_FILE="/etc/cups/cupsd.conf"

cp -f "$CUPS_FILE" "${CUPS_FILE}.bak"

echo "[INFO] Backup created:"
echo "       ${CUPS_FILE}.bak"

awk '
!/^[[:space:]]*Browsing[[:space:]]+/ &&
!/^[[:space:]]*BrowseLocalProtocols[[:space:]]+/ &&
!/^[[:space:]]*BrowseRemoteProtocols[[:space:]]+/
' "$CUPS_FILE" > "${CUPS_FILE}.tmp"

if ! grep -q "Browsing Off" "${CUPS_FILE}.tmp"; then
    sed -i '/^Listen \/run\/cups\/cups.sock/a Browsing Off\nBrowseLocalProtocols none\nBrowseRemoteProtocols none' "${CUPS_FILE}.tmp"
fi

mv "${CUPS_FILE}.tmp" "$CUPS_FILE"

systemctl restart cups

############################################
# 6. ADD MADMIN TO LPADMIN
############################################

echo
echo "[STEP 6] Ensuring madmin is in lpadmin group..."

if id "madmin" &>/dev/null; then

    /sbin/usermod -aG lpadmin madmin

    echo "[INFO] User madmin added to lpadmin"

else

    echo "[WARN] User madmin does not exist"

fi

############################################
# 7. CONFIGURE PRINTER
############################################

echo
echo "[STEP 7] Configuring printer MX00001..."

while true; do

    read -rp "Enter printer IP address: " PRINTER_IP

    if [[ -z "${PRINTER_IP}" ]]; then
        echo "[ERROR] Printer IP cannot be empty"
        continue
    fi

    if ! [[ "$PRINTER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "[ERROR] Invalid IP format"
        continue
    fi

    break

done

echo "[INFO] Using printer IP: $PRINTER_IP"

lpadmin -p MX00001 -E \
    -v "socket://${PRINTER_IP}:9100" \
    -m drv:///sample.drv/zebraep2.ppd \
    -o PageSize=w288h432 \
    -o media=w288h432 \
    -o fit-to-page=false \
    -o sides=one-sided \
    -o job-sheets=none,none \
    -o printer-is-shared=false

lpoptions -d MX00001

echo "[INFO] Printer set as default"

############################################
# 8. RESTART CUPS
############################################

echo
echo "[STEP 8] Restarting CUPS..."

systemctl restart cups

############################################
# 9. VERIFY
############################################

echo
echo "[STEP 9] Verifying configuration..."

lpoptions -p MX00001 || true
lpstat -p || true

echo
echo "================================================="
echo "PRINTER SETUP COMPLETED: $(date)"
echo "================================================="
