#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_mod="custom_blocks"

usage() {
  cat <<'USAGE'
usage: ./run.sh <command> [mod]

commands:
  check     verify versions agree, the changelog names this version, and a token exists
  build     check, then compile the mod jar
  pack      build, then write the .mcaddon and .mrpack into <mod>/dist/
  dry-run   pack, then print the Modrinth payload without uploading
  publish   pack, then upload the version to Modrinth
  release   publish, then create the GitHub release carrying both packs
  version   print the version this release would carry

mod defaults to custom_blocks.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

step() {
  echo
  echo "== $*"
}

read_property() {
  local file="$1" key="$2"

  sed -n "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//p" "$file" \
    | head -1 \
    | sed -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"
}

load_versions() {
  local properties="$here/gradle.properties"
  local pack_env="$mod_dir/pack.env"

  [[ -f $properties ]] || fail "$properties is missing"
  [[ -f $pack_env ]] || fail "$pack_env is missing"

  mod_version="$(read_property "$properties" mod_version)"
  minecraft_version="$(read_property "$properties" minecraft_version)"
  loader_version="$(read_property "$properties" loader_version)"

  pack_version="$(read_property "$pack_env" PACK_VERSION)"
  pack_minecraft_version="$(read_property "$pack_env" MC_VERSION)"
  pack_loader_version="$(read_property "$pack_env" FABRIC_LOADER_VERSION)"
  pack_name="$(read_property "$pack_env" PACK_NAME)"

  [[ -n $mod_version ]] || fail "mod_version is not set in gradle.properties"
  [[ -n $minecraft_version ]] || fail "minecraft_version is not set in gradle.properties"
}

has_modrinth_token() {
  [[ -n ${MODRINTH_TOKEN:-} ]] && return 0
  [[ -f "$here/.env" ]] && grep -qE '^[[:space:]]*(export[[:space:]]+)?MODRINTH_TOKEN=.' "$here/.env"
}

cmd_check() {
  load_versions

  local problems=0

  if [[ $mod_version != "$pack_version" ]]; then
    echo "mod_version is $mod_version but PACK_VERSION is $pack_version" >&2
    problems=$((problems + 1))
  fi

  if [[ $minecraft_version != "$pack_minecraft_version" ]]; then
    echo "minecraft_version is $minecraft_version but MC_VERSION is $pack_minecraft_version" >&2
    problems=$((problems + 1))
  fi

  if [[ $loader_version != "$pack_loader_version" ]]; then
    echo "loader_version is $loader_version but FABRIC_LOADER_VERSION is $pack_loader_version" >&2
    problems=$((problems + 1))
  fi

  if [[ -f "$mod_dir/CHANGELOG.md" ]]; then
    if ! grep -qE "^#+[[:space:]]*v?${mod_version}([[:space:]]|$)" "$mod_dir/CHANGELOG.md"; then
      echo "$mod_dir/CHANGELOG.md has no heading for $mod_version, so the published changelog describes an older release" >&2
      problems=$((problems + 1))
    fi
  else
    echo "$mod_dir/CHANGELOG.md is missing, so the version would publish without a changelog" >&2
    problems=$((problems + 1))
  fi

  if ! has_modrinth_token; then
    echo "no MODRINTH_TOKEN in the environment and no MODRINTH_TOKEN= line in .env" >&2
    problems=$((problems + 1))
  fi

  if ! compgen -G "$mod_dir/vendor/mods/*.jar" >/dev/null; then
    echo "note: no jar in $mod_dir/vendor/mods/, so the .mrpack will be skipped"
  fi

  if [[ -d "$here/.git" ]] && [[ -n "$(git -C "$here" status --porcelain)" ]]; then
    echo "note: the working tree has uncommitted changes"
  fi

  (( problems == 0 )) || fail "$problems problem(s) above must be fixed before publishing"

  echo "$mod version $mod_version for Minecraft $minecraft_version, Fabric Loader $loader_version"
}

cmd_version() {
  load_versions
  echo "${mod_version}+${minecraft_version}"
}

cmd_build() {
  cmd_check
  step "building the mod jar"
  "$here/gradlew" ":${mod}:build"
}

cmd_pack() {
  cmd_build
  step "writing $mod/dist/"
  (cd "$mod_dir" && ./package.sh)
}

cmd_dry_run() {
  cmd_pack
  step "printing the Modrinth payload, uploading nothing"
  "$here/gradlew" ":${mod}:modrinth" -PmodrinthDebug
}

cmd_publish() {
  cmd_pack
  step "uploading to Modrinth"
  "$here/gradlew" ":${mod}:modrinth"
}

cmd_release() {
  cmd_publish

  step "creating the GitHub release"

  command -v gh >/dev/null || fail "gh is not installed, so the GitHub release cannot be created"

  local tag="v${mod_version}"
  local prefix="${pack_name// /}"
  local assets=()

  for asset in "$mod_dir/dist/${prefix}-${mod_version}.mcaddon" "$mod_dir/dist/${prefix}-${mod_version}.mrpack"; do
    [[ -f $asset ]] && assets+=("$asset")
  done

  (( ${#assets[@]} > 0 )) || fail "nothing in $mod_dir/dist/ to attach"

  gh release create "$tag" "${assets[@]}" --notes "${pack_name} ${mod_version}"
}

command="${1:-}"
mod="${2:-$default_mod}"
mod_dir="$here/$mod"

[[ -n $command ]] || { usage; exit 1; }
[[ -d $mod_dir ]] || fail "no module at $mod_dir"

case "$command" in
  check) cmd_check ;;
  version) cmd_version ;;
  build) cmd_build ;;
  pack) cmd_pack ;;
  dry-run) cmd_dry_run ;;
  publish) cmd_publish ;;
  release) cmd_release ;;
  -h | --help | help) usage ;;
  *) usage; exit 1 ;;
esac
