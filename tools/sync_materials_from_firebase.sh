#!/usr/bin/env bash
# Tarik materi terbaru dari Firebase RTDB ke assets/data/materials.json
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/data/materials.json"
DB_URL="${FIREBASE_DATABASE_URL:-https://netlearn-3f933-default-rtdb.asia-southeast1.firebasedatabase.app}"

mkdir -p "$(dirname "$OUT")"
curl -fsSL "$DB_URL/materials.json" -o "$OUT"

python3 - "$OUT" <<'PY'
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
for key in sorted(data, key=lambda k: data[k].get("order", 0)):
    m = data[key]
    print(f"  {m['id']}: {m['title']} ({len(m.get('slides', []))} slide)")
PY

echo "Saved to $OUT"
