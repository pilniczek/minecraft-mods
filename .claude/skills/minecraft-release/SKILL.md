---
name: minecraft-release
description: Cut a release of a mod in this repository, producing the .mrpack modpack for Java Edition players and the .mcaddon for Bedrock Edition players and attaching both to a GitHub release. Use this skill whenever the user wants to release, ship, publish, tag or version a mod, wants to hand a build to friends, asks how players install it, or asks why a built pack does not import into the Modrinth App or the Bedrock game. Use it even when the user only says something like "send this to my friends" or "make a new version", because the version numbers live in two files that must agree and the packaging has prerequisites that fail quietly.
---

# Cutting a release

Each mod produces two artifacts that go on one GitHub release, so Java and Bedrock players use the same link:

- `dist/<Name>-<version>.mrpack` — a Modrinth modpack. The Modrinth App installs Fabric Loader itself and copies the bundled mods in.
- `dist/<Name>-<version>.mcaddon` — the two Bedrock packs zipped. Opening it imports both.

Neither requires the player to touch a game directory, which is the whole point of shipping this way rather than handing over a bare jar.

## Version numbers live in two files

`mod_version` in the repository root `gradle.properties` is what `fabric.mod.json` interpolates at build time. `PACK_VERSION` in the module's `pack.env` names the output files and fills `versionId` in the modpack manifest.

They are separate because one is a Gradle property and one is read by a shell script, and nothing enforces agreement. Raise both, to the same value, or players get an instance whose mod version and pack version disagree, and updates collide instead of replacing cleanly.

`MC_VERSION` and `FABRIC_LOADER_VERSION` in `pack.env` must also match `minecraft_version` and `loader_version` in `gradle.properties`. A mismatch produces a pack that installs a loader the jar was not built against, which fails at the player's end rather than yours.

## Steps

```
./gradlew :custom_blocks:<block>:build
cd custom_blocks/<block> && ./package.sh
```

`package.sh` syncs the texture through `build.sh`, then writes both artifacts into `dist/`.

The `.mcaddon` needs only the Bedrock pack folders, so it always builds. The `.mrpack` needs three things and names whichever is missing rather than failing obscurely:

1. `FABRIC_LOADER_VERSION` set in `pack.env`.
2. The mod jar in the module's `build/libs/`, which is why the Gradle build comes first.
3. The Fabric API jar in the module's `vendor/mods/`, downloaded by hand and not committed.

Then attach both to one release:

```
gh release create v<version> \
  custom_blocks/<block>/dist/<Name>-<version>.mrpack \
  custom_blocks/<block>/dist/<Name>-<version>.mcaddon \
  --notes "<Name> <version>"
```

Push the branch before creating the release, or the tag points at history GitHub does not have.

## Why the jars are bundled rather than linked

The modpack manifest supports a `files[]` array of remote downloads, but Modrinth accepts only URLs on `cdn.modrinth.com`, `github.com`, `raw.githubusercontent.com` and `gitlab.com`, and each entry needs SHA-1 and SHA-512 hashes. Putting the jars in `overrides/mods/` instead avoids the URLs, the hashes and the need to publish the mod anywhere, so an unlisted mod ships as easily as a published one. Fabric API is Apache-2.0, so redistributing it this way is fine.

Keep `files[]` empty unless someone deliberately wants remote downloads.

## Before releasing

- The Java mod has been loaded in game at least once, not merely compiled. `./gradlew :custom_blocks:<block>:runClient` and place the block.
- The `.mcaddon` has been imported on Bedrock if the Bedrock half changed, since a texture key binding failure there is silent.
- The Status column in the root `README.md` and the module README's Status section still describe reality.
- The working tree is committed and pushed.

## If something is wrong

| Symptom | Cause |
| --- | --- |
| `package.sh` skips the mrpack | One of the three prerequisites above; the message names it. |
| Modrinth App refuses the pack | `dependencies` in `modrinth.index.json` names a Minecraft or loader version that does not exist. |
| Players get a loader mismatch | `pack.env` and `gradle.properties` disagree on `MC_VERSION` or `FABRIC_LOADER_VERSION`. |
| Bedrock import does nothing | Manifest UUIDs collide with an already-installed pack. |
| Release tag points at nothing | The branch was not pushed before `gh release create`. |

## Distribution routes that do not apply

The Bedrock Marketplace is partner-gated, commercial and reviewed over weeks, so it is not a route for sharing with friends. Java Edition has no marketplace at all.

A Java mod is code, so a server never pushes it to clients; `resource-pack` in `server.properties` sends textures only and cannot add a block. Bedrock is the opposite: packs applied to a Realm or listed in a dedicated server's world pack files download to joining clients automatically, which is worth suggesting when the group already shares a world.
