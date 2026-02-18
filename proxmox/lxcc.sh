#!/usr/bin/env bash
set -e

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <input.tar.xz> <user-data> <meta-data> <output.tar.xz>"
  exit 1
fi

INPUT="$1"
USER_DATA="$2"
META_DATA="$3"
OUTPUT="$4"

# Select tar implementation
if [[ "$(uname)" == "Darwin" ]]; then
  TAR="gtar"
else
  TAR="tar"
fi

# Ensure GNU tar is available
if ! $TAR --version 2>/dev/null | grep -q "GNU tar"; then
  echo "GNU tar required. On macOS: brew install gnu-tar"
  exit 1
fi

TMP_TAR="$(mktemp).tar"

# 1. Decompress
xz -dc "$INPUT" > "$TMP_TAR"

# 2. Remove cloud-init.disabled if present
if $TAR -tf "$TMP_TAR" | grep -q '^./etc/cloud/cloud-init.disabled$'; then
  $TAR --delete -f "$TMP_TAR" ./etc/cloud/cloud-init.disabled
fi

# 3. Inject user-data
$TAR --owner=0 --group=0 \
  --transform='s|^.*$|var/lib/cloud/seed/nocloud/user-data|' \
  -rf "$TMP_TAR" "$USER_DATA"

# 4. Inject meta-data
$TAR --owner=0 --group=0 \
  --transform='s|^.*$|var/lib/cloud/seed/nocloud/meta-data|' \
  -rf "$TMP_TAR" "$META_DATA"

# 5. Recompress
xz -z -c "$TMP_TAR" > "$OUTPUT"

# 6. Cleanup
rm -f "$TMP_TAR"

echo "Created: $OUTPUT"