#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
texture="$here/art/eye_block.png"

cp "$texture" "$here/src/main/resources/assets/custom_blocks/textures/block/eye_block.png"
cp "$texture" "$here/bedrock/eye_block_rp/textures/blocks/eye_block.png"

echo "texture synced to src and bedrock"
