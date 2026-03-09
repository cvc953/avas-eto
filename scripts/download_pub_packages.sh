#!/usr/bin/env bash
set -euo pipefail

PACKAGES_FILE=${1:-}
if [[ -z "$PACKAGES_FILE" ]]; then
  cat <<EOF
Usage: $0 packages.txt
packages.txt should contain lines like:
  awesome_notifications@0.11.0
  flutter_riverpod@2.6.1
Blank lines and lines starting with # are ignored.
This script downloads each package tarball from pub.dev and extracts it into
$HOME/.pub-cache/hosted/pub.dev/<package>-<version>
EOF
  exit 1
fi

if [[ ! -f "$PACKAGES_FILE" ]]; then
  echo "File not found: $PACKAGES_FILE"
  exit 1
fi

CURL_OPTS=(--fail --location --retry 3 --retry-delay 2 --progress-bar)
CACHE_DIR="$HOME/.pub-cache/hosted/pub.dev"
mkdir -p "$CACHE_DIR"

echo "Using cache dir: $CACHE_DIR"

while IFS= read -r line || [[ -n "$line" ]]; do
  # strip whitespace
  line="${line%%+([[:space:]])}"
  line="${line##+([[:space:]])}"
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  if [[ ! "$line" =~ ^([^@]+)@(.+)$ ]]; then
    echo "Skipping invalid line: $line"
    continue
  fi

  pkg="${BASH_REMATCH[1]}"
  ver="${BASH_REMATCH[2]}"
  dest="$CACHE_DIR/${pkg}-${ver}"

  if [[ -d "$dest" && -n "$(ls -A "$dest")" ]]; then
    echo "Skipping $pkg@$ver (already in cache)"
    continue
  fi

  tmpfile="/tmp/${pkg}-${ver}.download"
  url="https://pub.dev/packages/${pkg}/versions/${ver}/download"

  echo "Downloading $pkg@$ver from $url"
  if ! curl "${CURL_OPTS[@]}" -o "$tmpfile" "$url" ; then
    echo "Failed to download $pkg@$ver"
    rm -f "$tmpfile"
    continue
  fi

  mtype=$(file -b --mime-type "$tmpfile" || true)
  mkdir -p "$dest"
  case "$mtype" in
    application/gzip|application/x-gzip)
      tar -xzf "$tmpfile" -C "$dest" --strip-components=1 || { echo "Tar extraction failed for $tmpfile"; rm -f "$tmpfile"; rm -rf "$dest"; continue; }
      ;;
    application/zip)
      unzip -q "$tmpfile" -d "$dest" || { echo "Unzip failed for $tmpfile"; rm -f "$tmpfile"; rm -rf "$dest"; continue; }
      ;;
    application/octet-stream)
      # try tar first
      if tar -tzf "$tmpfile" >/dev/null 2>&1; then
        tar -xzf "$tmpfile" -C "$dest" --strip-components=1 || { echo "Tar extraction failed for $tmpfile"; rm -f "$tmpfile"; rm -rf "$dest"; continue; }
      else
        echo "Unknown binary format for $tmpfile; please inspect manually.";
        rm -f "$tmpfile"; rm -rf "$dest"; continue
      fi
      ;;
    text/html*)
      echo "Downloaded HTML for $pkg@$ver — likely an error page. Inspect $tmpfile";
      rm -f "$tmpfile"; rm -rf "$dest"; continue
      ;;
    *)
      # Attempt a generic tar extraction as a fallback
      if tar -xzf "$tmpfile" -C "$dest" --strip-components=1 2>/dev/null; then
        :
      else
        echo "Unknown mime type: $mtype for $pkg@$ver; head of file:";
        head -n 20 "$tmpfile" || true;
        rm -f "$tmpfile"; rm -rf "$dest"; continue
      fi
      ;;
  esac

  rm -f "$tmpfile"
  echo "Installed $pkg@$ver -> $dest"
done < "$PACKAGES_FILE"

echo "Done. Now run 'flutter pub get' or 'dart pub get' in your project."