#!/usr/bin/env bash

set -uo pipefail

echo "================================================="
echo "CHROME VERSION MANAGER STARTED: $(date)"
echo "================================================="

############################################
# CHROME VERSION MANAGER
############################################

TARGET_USER="${SUDO_USER:-user}"
USER_HOME=$(eval echo "~$TARGET_USER")

CHROME_PROFILE="$USER_HOME/.config/google-chrome"

CURRENT_VERSION=$(
google-chrome --version 2>/dev/null \
| grep -oP '[0-9.]+' \
| head -n1
)

echo
echo "[INFO] Current version: ${CURRENT_VERSION:-Not installed}"

############################################
# FETCH AVAILABLE UPGRADE VERSION
############################################

echo
echo "[STEP 1] Updating apt cache..."

apt update

echo
echo "[STEP 2] Fetching available versions..."

mapfile -t UPGRADE_VERSIONS < <(
apt-cache madison google-chrome-stable 2>/dev/null \
| awk '{print $3}' \
| grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$' \
| sort -Vu
)

LATEST_UPGRADE="${UPGRADE_VERSIONS[-1]:-}"

############################################
# VERIFIED DOWNGRADE VERSIONS
############################################

DOWNGRADE_URLS=(
"http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_148.0.7778.167-1_amd64.deb"
"http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_147.0.7727.137-1_amd64.deb"
"http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_146.0.7680.177-1_amd64.deb"
"http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_143.0.7499.40-1_amd64.deb"
)

DOWNGRADE_NAMES=()

for url in "${DOWNGRADE_URLS[@]}"; do
    DOWNGRADE_NAMES+=("$(basename "$url")")
done

############################################
# MENU
############################################

echo
echo "Available options:"
echo

echo "[UPGRADE]"

if [ -n "$LATEST_UPGRADE" ]; then
    echo "  [u] Upgrade to latest: $LATEST_UPGRADE"
else
    echo "  [u] No upgrade available"
fi

echo
echo "[DOWNGRADE]"

for i in "${!DOWNGRADE_NAMES[@]}"; do
    printf "  [d%d] %s\n" "$((i+1))" "${DOWNGRADE_NAMES[$i]}"
done

echo
echo "  [0] Exit"
echo

read -rp "Choose option: " CHOICE

SELECTED_URL=""
SELECTED_VERSION=""
ACTION="none"

############################################
# CHOICE HANDLER
############################################

case "$CHOICE" in

    u|U)
        SELECTED_VERSION="$LATEST_UPGRADE"
        ACTION="upgrade"
        ;;

    d1|d2|d3|d4)
        INDEX="${CHOICE#d}"
        INDEX=$((INDEX-1))
        SELECTED_URL="${DOWNGRADE_URLS[$INDEX]}"
        ACTION="downgrade"
        ;;

    0|"")
        ACTION="exit"
        ;;

    *)
        echo "[WARN] Invalid selection"
        ACTION="exit"
        ;;
esac

############################################
# EXECUTE ACTION
############################################

if [ "$ACTION" = "downgrade" ]; then

    echo
    echo "[STEP 3] Downloading package..."

    wget -O /tmp/chrome.deb "$SELECTED_URL"

    if [ ! -f /tmp/chrome.deb ]; then
        echo "[ERROR] Download failed"
        exit 1
    fi

    echo
    echo "[STEP 4] Installing downgrade..."

    dpkg -i /tmp/chrome.deb || true

    apt-get install -f -y

    apt-mark hold google-chrome-stable >/dev/null 2>&1 || true

    echo "[INFO] Downgrade completed"

elif [ "$ACTION" = "upgrade" ]; then

    echo
    echo "[STEP 3] Removing package hold..."

    apt-mark unhold google-chrome-stable >/dev/null 2>&1 || true

    echo
    echo "[STEP 4] Installing upgrade..."

    apt install -y \
        --allow-downgrades \
        --allow-change-held-packages \
        google-chrome-stable="$SELECTED_VERSION"

    echo "[INFO] Upgrade completed"

else

    echo
    echo "[INFO] No changes applied"

fi

############################################
# FINAL VERSION CHECK
############################################

echo
echo "[STEP 5] Final version check"

google-chrome --version || true

############################################
# PROFILE RESET AFTER DOWNGRADE
############################################

if [ "$ACTION" = "downgrade" ]; then

    echo
    echo "[STEP 6] Cleaning Chrome profile"

    sudo -u "$TARGET_USER" pkill -9 -x chrome 2>/dev/null || true
    sudo -u "$TARGET_USER" pkill -9 -x chrome_crashpad_handler 2>/dev/null || true

    sleep 2

    rm -rf "$USER_HOME/.config/google-chrome"

    echo "[INFO] Chrome profile cleaned"
fi

echo
echo "================================================="
echo "CHROME VERSION MANAGER COMPLETED: $(date)"
echo "================================================="
