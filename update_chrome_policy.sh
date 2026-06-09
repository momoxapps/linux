#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo "CHROME POLICY UPDATE STARTED: $(date)"
echo "================================================="

echo
echo "[STEP 1] Preparing directories..."

POLICY_DIR="/etc/opt/chrome/policies/managed"
BACKUP_DIR="/etc/opt/chrome/policies/backup"

POLICY_FILE="${POLICY_DIR}/default_policy.json"

mkdir -p "$POLICY_DIR"
mkdir -p "$BACKUP_DIR"

TMP_FILE=$(mktemp)

echo "[INFO] Directories ready"

echo
echo "[STEP 2] Creating backup..."

if [ -f "$POLICY_FILE" ]; then

```
cp "$POLICY_FILE" \
   "${BACKUP_DIR}/default_policy.json.bak"

echo "[INFO] Backup created:"
echo "       ${BACKUP_DIR}/default_policy.json.bak"
```

fi

echo
echo "[STEP 3] Detecting station number..."

STATION=""

if [ -f "$POLICY_FILE" ]; then

```
STATION=$(
    grep -oP 'shipping_outbound/pack_nll/\K[0-9]+' \
    "$POLICY_FILE" \
    | head -n1 \
    || true
)
```

fi

if [ -z "${STATION:-}" ]; then

```
echo "[WARN] No station number found in existing policy"

while true; do

    read -rp "Enter station number: " STATION

    if [[ "$STATION" =~ ^[0-9]+$ ]]; then
        break
    fi

    echo "[ERROR] Station number must contain digits only"

done
```

else

```
echo "[INFO] Detected station number: $STATION"
```

fi

PACK_URL="https://app.lg.int.momox.biz/shipping_outbound/pack_nll/$STATION"

echo
echo "[INFO] Pack URL:"
echo "       $PACK_URL"

echo
echo "[STEP 4] Downloading policy template..."

python3 <<EOF
import json
import urllib.request

url = "https://raw.githubusercontent.com/momoxapps/lej/refs/heads/main/default_policy.json"

with urllib.request.urlopen(url) as r:
data = json.loads(r.read().decode("utf-8"))

pack_url = "$PACK_URL"

for item in data.get("ManagedBookmarks", []):
if item.get("name") == "B&M Pack":
item["url"] = pack_url

data["RestoreOnStartupURLs"] = [pack_url]

with open("$TMP_FILE", "w") as f:
json.dump(data, f, indent=2)
EOF

echo "[INFO] Policy template updated"

echo
echo "[STEP 5] Installing policy..."

mv "$TMP_FILE" "$POLICY_FILE"

chmod 644 "$POLICY_FILE"

echo "[INFO] Chrome policy installed successfully"

echo
echo "[STEP 6] Verification"

grep -n "pack_nll" "$POLICY_FILE" || true

echo
echo "================================================="
echo "CHROME POLICY UPDATE COMPLETED: $(date)"
echo "================================================="
