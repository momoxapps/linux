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
# STEP 1 - PATCH ONBOARD
########################################

echo
echo "[STEP 1] Patching Onboard Keyboard.py"

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
    print("[INFO] Patch applied successfully")
else:
    print("[WARN] Pattern not found, file may already be patched")
PY

########################################
# STEP 2 - RESTART ONBOARD
########################################

echo
echo "[STEP 2] Restarting Onboard"

pkill onboard 2>/dev/null || true

su - user -c 'DISPLAY=:0 onboard &' >/dev/null 2>&1

echo "[INFO] Onboard restarted"

########################################
# STEP 3 - CONFIGURE AT-SPI
########################################

echo
echo "[STEP 3] Configuring key-synth"

su - user -c '
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

gsettings set org.onboard.keyboard key-synth "AT-SPI"
'

echo "[INFO] key-synth set to AT-SPI"

########################################
# STEP 4 - CONFIGURE SNIPPETS
########################################

echo
echo "[STEP 4] Configuring snippets"

su - user -c '
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

gsettings set org.onboard snippets "\
[\
\"0:E-:E-\",\
\"1:lej_:lej_\",\
\"2:@momox.biz:@momox.biz\",\
\"3:@:@\",\
\"4:--:--\",\
\"5:--:--\",\
\"6:--:--\",\
\"7:--:--\",\
\"8:--:--\",\
\"9:--:--\",\
\"10:--:--\",\
\"11:--:--\",\
\"12:--:--\",\
\"13:--:--\",\
\"14:--:--\",\
\"15:--:--\"\
]"
'

echo "[INFO] Snippets configured"

########################################
# DONE
########################################

echo
echo "====================================="
echo "SETUP ONBOARD COMPLETED: $(date)"
echo "====================================="
