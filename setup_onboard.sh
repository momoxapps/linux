#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/setup_onboard.log"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "====================================="
echo "SETUP ONBOARD STARTED: $(date)"
echo "====================================="

########################################

# DETECT TARGET USER

########################################

TARGET_USER="${SUDO_USER:-user}"

if ! id "$TARGET_USER" >/dev/null 2>&1; then
echo "[WARN] User '$TARGET_USER' not found"

TARGET_USER=$(awk -F: '$3>=1000 && $3<65534 {print $1; exit}' /etc/passwd)

if [ -z "${TARGET_USER:-}" ]; then
    echo "[ERROR] No valid desktop user found"
    exit 1
fi

fi

echo "[INFO] Using user: $TARGET_USER"

########################################

# STEP 1 - PATCH ONBOARD

########################################

echo
echo "[STEP 1] Disable snippet editor popup on long press"

SOURCE="/usr/lib/python3/dist-packages/Onboard/Keyboard.py"
BACKUP="${SOURCE}.bak"

cp -f "$SOURCE" "$BACKUP"

echo "[INFO] Backup created:"
echo "       $BACKUP"

python3 - <<'PY'
from pathlib import Path

f = Path("/usr/lib/python3/dist-packages/Onboard/Keyboard.py")

txt = f.read_text()

old = """elif key_type == KeyCommon.MACRO_TYPE:
                snippet_id = int(key.code)
                self._edit_snippet(view, snippet_id)
                long_pressed = True"""

new = """elif key_type == KeyCommon.MACRO_TYPE:
                long_pressed = True"""

if new in txt:
    print("[INFO] Patch already installed")

elif old in txt:
    txt = txt.replace(old, new, 1)
    f.write_text(txt)
    print("[INFO] Patch applied successfully")

else:
    print("[WARN] Expected code block not found")
PY

########################################

# STEP 2 - RESTART ONBOARD

########################################

echo
echo "[STEP 2] Restart Onboard virtual keyboard"

pkill onboard 2>/dev/null || true

su - "$TARGET_USER" -c '
DISPLAY=:0 onboard >/dev/null 2>&1 &
' || true

sleep 1

echo "[INFO] Onboard restarted"

########################################

# STEP 3 - CONFIGURE AT-SPI

########################################

echo
echo "[STEP 3] Enable AT-SPI key injection"

su - "$TARGET_USER" -c '
export DISPLAY=:0

BUS="/run/user/$(id -u)/bus"

if [ -S "$BUS" ]; then
export DBUS_SESSION_BUS_ADDRESS="unix:path=$BUS"
fi

if command -v gsettings >/dev/null 2>&1; then
gsettings set org.onboard.keyboard key-synth "AT-SPI"
fi
'

VERIFY_ATSPI=$(su - "$TARGET_USER" -c '
gsettings get org.onboard.keyboard key-synth 2>/dev/null
' || true)

if echo "$VERIFY_ATSPI" | grep -q "AT-SPI"; then
echo "[INFO] AT-SPI enabled successfully"
else
echo "[WARN] Unable to verify AT-SPI configuration"
fi

########################################

# STEP 4 - CONFIGURE SNIPPETS

########################################

echo
echo "[STEP 4] Configure predefined text snippets"

su - "$TARGET_USER" -c '
export DISPLAY=:0

BUS="/run/user/$(id -u)/bus"

if [ -S "$BUS" ]; then
export DBUS_SESSION_BUS_ADDRESS="unix:path=$BUS"
fi

gsettings set org.onboard snippets "["0:E-1:E-","1:lej_:lej_","2:@momox.biz:@momox.biz","3:@:@","4:--:--","5:--:--","6:--:--","7:--:--","8:--:--","9:--:--","10:--:--","11:--:--","12:--:--","13:--:--","14:--:--","15:--:--"]"
'

VERIFY_SNIPPETS=$(su - "$TARGET_USER" -c '
gsettings get org.onboard snippets 2>/dev/null
' || true)

if echo "$VERIFY_SNIPPETS" | grep -q "lej_"; then
echo "[INFO] Snippets configured successfully"
else
echo "[WARN] Unable to verify snippet configuration"
fi

########################################

# DONE

########################################

echo
echo "====================================="
echo "SETUP ONBOARD COMPLETED: $(date)"
echo "====================================="
