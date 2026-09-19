---
name: minecraft-release
description: Cut a release of a mod in this repository, publishing the Java mod jar to Modrinth with Minotaur and attaching the Bedrock .mcaddon to a GitHub release. Use this skill whenever the user wants to release, ship, publish, tag or version a mod, wants to hand a build to friends, asks how players install it, asks about Modrinth projects, review queues, tokens or visibility, asks whether a project follows Modrinth's content rules, terms, copyright or AI policy, asks what to disclose or what a project title, summary or description must contain, or asks why a built pack does not import into the Modrinth App or the Bedrock game. Use it even when the user only says something like "send this to my friends" or "make a new version", because the version numbers live in two files that must agree, the packaging has prerequisites that fail quietly, and a first Modrinth publish needs a manual review that cannot be automated.
---

# Cutting a release

Java and Bedrock ship by different routes, and the difference is not cosmetic.

- **Java**: the mod jar goes to Modrinth as a **mod** project. Installing it adds the mod to a profile the player already has, and the Modrinth App resolves the declared Fabric API dependency itself.
- **Bedrock**: `dist/<Name>-<version>.mcaddon`, the two packs zipped, attached to a GitHub release. Opening it imports both.

`dist/<Name>-<version>.mrpack` also gets built and attached, but it is for handing someone a whole preconfigured instance, not for publishing. See the section on mod versus modpack below before suggesting it.

## Version numbers live in two files

`mod_version` in the repository root `gradle.properties` is what `fabric.mod.json` interpolates at build time, and what Minotaur turns into the Modrinth version number. `PACK_VERSION` in the module's `pack.env` names the output files and fills `versionId` in the modpack manifest.

They are separate because one is a Gradle property and one is read by a shell script, and the build enforces no agreement between them. Raise both, to the same value, or players get an instance whose mod version and pack version disagree, and updates collide instead of replacing cleanly. `./run.sh check` compares them, and every other `run.sh` command runs it first.

A number that has been published is spent. Modrinth rejects a duplicate version number, and deleting a version to re-upload the same number leaves Modrinth App instances reporting an update that never completes. A correction to a released jar is a new version, never a replacement, so ask whether the change is worth a number before re-publishing at all: project page fields and a version's changelog are both editable in the web UI without touching the jar.

`MC_VERSION` and `FABRIC_LOADER_VERSION` in `pack.env` must also match `minecraft_version` and `loader_version` in `gradle.properties`. A mismatch produces a pack that installs a loader the jar was not built against, which fails at the player's end rather than yours.

## First publish of a mod, once only

Modrinth reviews every new project by hand. Minotaur cannot create projects, only upload versions to one that exists, so this part is the user's to do in a browser and no amount of tooling shortens it.

**There is no project type to pick.** The creation dialog offers only **Type** (`Project` or `Server`, where `Server` means a server listing), **URL**, **Owner**, **Visibility** and **Summary**. Modrinth derives mod against modpack from the loaders on the first version: `fabric` makes it a mod, `mrpack` makes it a modpack. Anyone expecting a mod/modpack dropdown will not find one, and uploading the `.mrpack` first is how a project ends up the wrong type.

1. Create the project. Name is the mod name alone; a version number, a loader name or a tagline in it is a rejection reason. Visibility chosen here applies only **after** approval.
2. Put the URL slug in the module's `build.gradle` as `ext.modrinthProjectId`.
3. Upload the first version, through Minotaur or the web UI. Tags and content disclosures stay locked until a version exists, so this comes before the checklist rather than after it.
4. Complete the publishing checklist on the project page: description, license `MIT` matching the repository `LICENSE`, source link, categories, environment, and the content disclosures. The checklist gates the submit button, and every field on it is a content rule. [references/modrinth-rules.md](references/modrinth-rules.md) has what each one must contain.
5. Submit for review. Target is 24 to 48 hours. Editing while queued does not lose the queue place. A draft is visible only to project members, so the wait cannot be skipped by sharing a link.
6. After approval, **Unlisted** stays installable from a direct link while staying out of search; **Public** is searchable.

Repeatedly resubmitting without addressing moderation feedback risks account suspension, so read the rejection before resubmitting.

## Content rules

A rejection costs another review cycle, so the rules are cheaper to read than to rediscover. [references/modrinth-rules.md](references/modrinth-rules.md) maps all five legal pages onto this repository. Four of them decide whether a submit passes:

- **The description must answer three questions**: what the project adds, why someone should download it, and what they must know first. Here the third is Java with Fabric only, Fabric API required, Bedrock shipped separately. It needs a plain-text version, an English translation, and no headers standing in for body text.
- **The "Contains AI-generated content" disclosure is required** whenever a substantial portion of the code, or any part of the project page, is AI output. Code and docs written with an agent meet that, so it applies to every project in this repository. Separately, an icon or gallery image created or derived from generative AI is prohibited outright, and a project may not be published if its contents are primarily AI output.
- **Title is the project name alone**, matching `fabric.mod.json` and the READMEs rather than the URL slug. The summary must not repeat the title and carries no formatting.
- **Ship only what is licensed.** A texture derived from someone else's work needs redistribution rights and credit, and the same PNG goes into both the jar and the Bedrock pack. Third-party mods are declared, never bundled, which is why the `.mrpack` stays on GitHub.

Raise asset provenance before a first publish rather than after: a rights complaint runs through DMCA, and repeat infringements cost the account rather than the project.

## Every release

```
./run.sh release [mod]
```

That is the whole path: version checks, jar, both packs, the Modrinth upload, then the GitHub release. `mod` defaults to `custom_blocks`. Each step is also a command of its own, and each runs the ones before it: `check`, `build`, `pack`, `dry-run`, `publish`, `release`, plus `version` to print what would be published.

Reach for the underlying commands when a single step is what is wanted:

```
./gradlew :<mod>:build
cd <mod> && ./package.sh
```

`package.sh` syncs the texture through `build.sh`, then writes both artifacts into `dist/`.

The `.mcaddon` needs only the Bedrock pack folders, so it always builds. The `.mrpack` needs three things and names whichever is missing rather than failing obscurely:

1. `FABRIC_LOADER_VERSION` set in `pack.env`.
2. The mod jar in the module's `build/libs/`, which is why the Gradle build comes first.
3. The Fabric API jar in the module's `vendor/mods/`, downloaded by hand and not committed.

Publish the Java half:

```
./gradlew :<mod>:modrinth
```

The token comes from `https://modrinth.com/settings/pats` and needs the `VERSION_CREATE` scope and nothing more. `gradle/mod-conventions.gradle` takes it from a `MODRINTH_TOKEN` environment variable when one is set, and otherwise from a `MODRINTH_TOKEN=` line in the gitignored `.env` at the repository root.

A token never belongs anywhere else: not in `gradle.properties`, not in a build file, not in a document, not in a commit message, and not echoed into terminal output that gets pasted around. Before committing, check that `.env` is still ignored, since an ignore rule lost in a merge turns the next `git add -A` into a leaked credential.

Everything else about the version is derived in `gradle/mod-conventions.gradle` from `gradle.properties` and the module's `ext` values, so a routine release edits no build file. The version changelog is the module's `CHANGELOG.md`.

Adding `-PmodrinthDebug` prints the full payload and skips the upload, which is the way to check a change before it becomes a public version. It is not an offline mode: Minotaur builds its API client and resolves the project before it looks at the debug flag, so the token still has to be present and valid. Only an unresolvable slug is downgraded from a failure to a logged error.

## Testing the Bedrock half on Windows

Bedrock Edition has no Linux client, so on a WSL setup the game runs on the Windows host and the packs have to cross over. The UWP install keeps its data at:

```
/mnt/c/Users/<user>/AppData/Local/Packages/Microsoft.MinecraftUWP_8wekyb3d8bbwe/LocalState/games/com.mojang/
```

Copying the two pack folders into `development_behavior_packs/` and `development_resource_packs/` there loads them as development packs, which reread from disk each time the game starts. That beats importing the `.mcaddon` for iteration, because an import copies the packs in and a re-import collides on the fixed UUIDs.

```
target="/mnt/c/Users/<user>/AppData/Local/Packages/Microsoft.MinecraftUWP_8wekyb3d8bbwe/LocalState/games/com.mojang"
cp -r <mod>/bedrock/<modid>_bp "$target/development_behavior_packs/"
cp -r <mod>/bedrock/<modid>_rp "$target/development_resource_packs/"
```

The `.mcaddon` is still what ships, so test an actual import once before a release rather than only the development packs. A sandboxed session cannot write to `/mnt/c`, so this is the user's command to run.

Then the GitHub release, for the Bedrock half:

```
gh release create v<version> \
  <mod>/dist/<Name>-<version>.mcaddon \
  <mod>/dist/<Name>-<version>.mrpack \
  --notes "<Name> <version>"
```

Push the branch before creating the release, or the tag points at history GitHub does not have.

## Mod project or modpack project

A mod project holds a jar and installs into an existing profile. A modpack project holds a `.mrpack` and becomes a whole new instance with its own world. Which one a project is follows from the first version's loaders, so the choice is made by what is uploaded.

Someone who wants one extra block in the world they already play needs a mod project. Reach for a modpack only when the point is to hand over an entire preconfigured setup.

The distinction also decides how Fabric API travels. Modrinth requires third-party mods to be **declared, not bundled**, so a mod project names Fabric API in its dependency list. The `.mrpack` this repository builds bundles it in `overrides/mods/` instead, which is fine for a file handed over directly and would be rejected as a published modpack. Publishing that file would mean moving Fabric API into the manifest's `files[]` with SHA-1 and SHA-512 hashes and a URL on `cdn.modrinth.com`, `github.com`, `raw.githubusercontent.com` or `gitlab.com`, the only hosts accepted there.

## Before releasing

- The Java mod has been loaded in game at least once, not merely compiled. `./gradlew :<mod>:runClient` and place the block.
- Any crafting recipe has been crafted in game, since a recipe that never loads fails silently.
- The `.mcaddon` has been imported on Bedrock if the Bedrock half changed, since a texture key binding failure there is silent.
- Every shipped asset has known provenance, because the same texture goes into the jar and the Bedrock pack.
- The content disclosures still match what the project does, the AI one included.
- `CHANGELOG.md` in the module describes this version, because it becomes the public changelog.
- The Status column in the root `README.md` and the module README's Status section still describe reality.
- The working tree is committed and pushed.

## If something is wrong

| Symptom | Cause |
| --- | --- |
| `run.sh check` refuses to continue | The message names it: versions disagreeing across the two files, a changelog with no heading for this version, or no token. |
| Modrinth rejects the version number | That number is already published. Bump it; deleting the old version to reuse it breaks updates for anyone who installed it. |
| `package.sh` skips the mrpack | One of the three prerequisites above; the message names it. |
| `Cannot query the value of extension 'modrinth' property 'token'` | No `MODRINTH_TOKEN` environment variable and no `MODRINTH_TOKEN=` line in the root `.env`. `-PmodrinthDebug` does not avoid it. |
| Minotaur fails with an authentication error | The token is wrong, expired, or lacks `VERSION_CREATE`. |
| Minotaur cannot find the project | `ext.modrinthProjectId` does not match the URL slug, or no project has been created yet. |
| `Could not get unknown property 'remapJar'` | Minecraft is unobfuscated from 1.21.11 onwards, so `net.fabricmc.fabric-loom` configures no remapping and creates no `remapJar`. Upload `jar` instead. |
| The project came out as a modpack | The first version carried the `mrpack` loader. Type follows the first version's loaders and is not a setting. |
| Tags or disclosures cannot be edited | No version has been uploaded yet; both unlock only once one exists. |
| Review rejects the description | It misses one of the three required answers, has no plain-text version, or uses headers as body text. |
| Review rejects the summary or title | The summary repeats the title or carries formatting; the title carries a version, a loader, a tagline or the slug spelling. |
| An uploaded image is removed | It was created or derived from generative AI, which is prohibited anywhere on a project page. |
| A version fails review over an asset | Its provenance is unclear, or a third-party work ships without rights and credit. |
| Modrinth rejects the version's game version | `minecraft_version` names a version Modrinth's list does not carry; check `https://api.modrinth.com/v2/tag/game_version`. |
| Modrinth App refuses the pack | `dependencies` in `modrinth.index.json` names a Minecraft or loader version that does not exist. |
| Players get a loader mismatch | `pack.env` and `gradle.properties` disagree on `MC_VERSION` or `FABRIC_LOADER_VERSION`. |
| Bedrock import does nothing | Manifest UUIDs collide with an already-installed pack. |
| Release tag points at nothing | The branch was not pushed before `gh release create`. |
| The build warns about Gradle 10 | Loom emits it, not this repository. It clears with a major Loom release and nothing else. |

## Distribution routes that do not apply

The Bedrock Marketplace is partner-gated, commercial and reviewed over weeks, so it is not a route for sharing with friends.

A Java mod is code, so a server never pushes it to clients; `resource-pack` in `server.properties` sends textures only and cannot add a block. Bedrock is the opposite: packs applied to a Realm or listed in a dedicated server's world pack files download to joining clients automatically, which is worth suggesting when the group already shares a world.
