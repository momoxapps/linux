#!/usr/bin/env bash

set -uo pipefail

############################################
# ERROR HANDLER
############################################

handle_error() {
local exit_code=$?
local line_no=$1
local command="$2"

echo
echo "[ERROR] Command failed at line $line_no"
echo "[ERROR] Command: $command"
echo "[ERROR] Exit code: $exit_code"
echo

while true; do

    echo "Choose action:"
    echo "  [r] Retry"
    echo "  [c] Continue"
    echo "  [a] Abort"

    read -rp "> " choice

    case "$choice" in

        r|R)
            echo "[INFO] Retrying..."
            eval "$command"
            return 0
            ;;

        c|C)
            echo "[WARN] Continuing despite error..."
            return 0
            ;;

        a|A)
            echo "[INFO] Aborted by user."
            exit 1
            ;;

        *)
            echo "[WARN] Invalid choice."
            ;;

    esac
done

}

trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

############################################
# START
############################################

echo "================================================="
echo "WORKSTATION SETUP STARTED: $(date)"
echo "================================================="

############################################
# ONBOARD
############################################

echo
echo "[STEP 1] Configure Onboard virtual keyboard..."

wget -O /tmp/setup_onboard.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/setup_onboard.sh

bash /tmp/setup_onboard.sh

############################################
# XFCE PANEL
############################################

echo
echo "[STEP 2] Apply standardized XFCE panel layout..."

wget -O /tmp/fix_xfce_panel.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/fix_xfce_panel.sh

bash /tmp/fix_xfce_panel.sh

############################################
# POWER MENU
############################################

echo
echo "[STEP 3] Install power management menu..."

wget -O /tmp/update_shutdown_ask.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/update_shutdown_ask.sh

bash /tmp/update_shutdown_ask.sh

############################################
# CHROME VERSION
############################################

echo
echo "[STEP 4] Install or change Google Chrome version..."

wget -O /tmp/chrome_version_manager.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/chrome_version_manager.sh

bash /tmp/chrome_version_manager.sh

############################################
# PRINTER
############################################

echo
echo "[STEP 5] Configure label printer and CUPS..."

wget -O /tmp/setup_printer.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/setup_printer.sh

bash /tmp/setup_printer.sh

############################################
# SILENT PRINTING
############################################

echo
echo "[STEP 6] Enable silent printing in Google Chrome..."

wget -O /tmp/update_chrome_desktop.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/update_chrome_desktop.sh

bash /tmp/update_chrome_desktop.sh

############################################
# CHROME POLICY
############################################

echo
echo "[STEP 7] Configure Chrome enterprise policy..."

wget -O /tmp/update_chrome_policy.sh 
https://raw.githubusercontent.com/momoxapps/linux/main/update_chrome_policy.sh

bash /tmp/update_chrome_policy.sh

############################################
# DONE
############################################

echo
echo "================================================="
echo "WORKSTATION SETUP COMPLETED: $(date)"
echo "================================================="
