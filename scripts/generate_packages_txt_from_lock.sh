#!/usr/bin/env bash
set -euo pipefail
LOCK_FILE="pubspec.lock"
OUT_FILE="packages.txt"
if [[ ! -f "$LOCK_FILE" ]]; then
  echo "pubspec.lock not found"
  exit 1
fi

echo "Generating $OUT_FILE from $LOCK_FILE"

awk '/^packages:/{flag=1; next} flag && /^sdks:/{exit} flag {if ($1 ~ /^[a-zA-Z0-9_\-]+:$/) {pkg=substr($1,1,length($1)-1); version=""} if ($1=="version:") {gsub(/\"/,"",$2); version=$2; print pkg"@"version}}' "$LOCK_FILE" | grep -v '^flutter@' > "$OUT_FILE"

echo "Wrote $(wc -l < "$OUT_FILE") packages to $OUT_FILE"