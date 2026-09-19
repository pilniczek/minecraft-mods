#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
java_textures="$here/src/main/resources/assets/custom_blocks/textures/block"
bedrock_textures="$here/bedrock/custom_blocks_rp/textures/blocks"

mkdir -p "$java_textures" "$bedrock_textures"

shopt -s nullglob
count=0

for texture in "$here"/blocks/*/art/*.png; do
  cp "$texture" "$java_textures/"
  cp "$texture" "$bedrock_textures/"
  count=$((count + 1))
done

if [[ $count -eq 0 ]]; then
  echo "no textures found under blocks/*/art/, nothing to sync" >&2
  exit 1
fi

echo "$count texture(s) synced to src and bedrock"
