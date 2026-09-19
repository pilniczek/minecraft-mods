#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/pack.env"

slug="${PACK_NAME// /}"
shopt -s nullglob

zip_dir() {
  python3 - "$1" "$2" <<'PYZIP'
import os, sys, zipfile

src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
    for root, dirs, files in os.walk(src):
        dirs.sort()
        for name in sorted(files):
            full = os.path.join(root, name)
            archive.write(full, os.path.relpath(full, src))
PYZIP
}

build_mcaddon() {
  local staging="$here/dist/addon"
  rm -rf "$staging"
  mkdir -p "$staging"
  cp -r "$here/bedrock/custom_blocks_bp" "$here/bedrock/custom_blocks_rp" "$staging/"

  local out="$here/dist/${slug}-${PACK_VERSION}.mcaddon"
  rm -f "$out"
  zip_dir "$staging" "$out"
  echo "built $out"
}

build_mrpack() {
  if [[ -z "${FABRIC_LOADER_VERSION}" ]]; then
    echo "skipping mrpack: FABRIC_LOADER_VERSION is empty in pack.env" >&2
    return 0
  fi

  local mod_jars=("$here"/build/libs/*.jar)
  local vendor_jars=("$here"/vendor/mods/*.jar)

  if [[ ${#mod_jars[@]} -eq 0 ]]; then
    echo "skipping mrpack: no jar in build/libs/, run ./gradlew :custom_blocks:build first" >&2
    return 0
  fi
  if [[ ${#vendor_jars[@]} -eq 0 ]]; then
    echo "skipping mrpack: no jars in vendor/mods/, put Fabric API for ${MC_VERSION} there" >&2
    return 0
  fi

  local staging="$here/dist/modpack"
  rm -rf "$staging"
  mkdir -p "$staging/overrides/mods"

  local jar
  for jar in "${mod_jars[@]}"; do
    case "$jar" in
      *-sources.jar|*-dev.jar) continue ;;
    esac
    cp "$jar" "$staging/overrides/mods/"
  done
  cp "${vendor_jars[@]}" "$staging/overrides/mods/"

  cat > "$staging/modrinth.index.json" <<JSON
{
  "formatVersion": 1,
  "game": "minecraft",
  "versionId": "${PACK_VERSION}",
  "name": "${PACK_NAME}",
  "summary": "${PACK_SUMMARY}",
  "files": [],
  "dependencies": {
    "minecraft": "${MC_VERSION}",
    "fabric-loader": "${FABRIC_LOADER_VERSION}"
  }
}
JSON

  local out="$here/dist/${slug}-${PACK_VERSION}.mrpack"
  rm -f "$out"
  zip_dir "$staging" "$out"
  echo "built $out"
}

"$here/build.sh"
build_mcaddon
build_mrpack
