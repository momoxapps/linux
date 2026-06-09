#!/usr/bin/env bash

set -euo pipefail

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

if old in txt:
    txt = txt.replace(old, new, 1)
    f.write_text(txt)
    print("Patched successfully")
else:
    print("Pattern not found, file may already be patched")
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
# STEP 3 - ENABLE AT-SPI
########################################

echo
echo "[STEP 3] Enable AT-SPI key injection"

su - "$TARGET_USER" -c '
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

gsettings set org.onboard.keyboard key-synth "AT-SPI"
'

VERIFY_ATSPI=$(su - "$TARGET_USER" -c '
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

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

SNIPPETS='["0:E-:E-","1:lej_:lej_","2:@momox.biz:@momox.biz","3:@:@","4:--:--","5:--:--","6:--:--","7:--:--","8:--:--","9:--:--","10:--:--","11:--:--","12:--:--","13:--:--","14:--:--","15:--:--"]'

su - "$TARGET_USER" -c "
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
gsettings set org.onboard snippets '$SNIPPETS'
"

CURRENT=$(su - "$TARGET_USER" -c '
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
gsettings get org.onboard snippets
')

echo "[INFO] Current snippets:"
echo "$CURRENT"

if echo "$CURRENT" | grep -q "0:E-:E-"; then
echo "[INFO] Snippets configured successfully"
else
echo "[ERROR] Failed to configure snippets"
fi

########################################
# STEP 5 - RELOAD ONBOARD
########################################

echo
echo "[STEP 5] Reload Onboard configuration"

pkill onboard 2>/dev/null || true

su - "$TARGET_USER" -c '
DISPLAY=:0 onboard >/dev/null 2>&1 &
' || true

sleep 2

echo "[INFO] Onboard configuration reloaded"

########################################
# DONE
########################################

echo
echo "====================================="
echo "SETUP ONBOARD COMPLETED: $(date)"
echo "====================================="
