# minecraft-mods

Custom Minecraft blocks, built for both editions from one source of art.

Each mod lives in its own Gradle module and produces two shippable files: a `.mrpack` modpack for Java Edition players using the Modrinth App, and a `.mcaddon` for Bedrock Edition players. Both are attached to a GitHub release, and friends install by opening the file.

## Documentation

| Document | Covers |
| --- | --- |
| This file | Repository layout, toolchain, build and release commands, conventions. |
| [CUSTOM-BLOCK-MANUAL.md](CUSTOM-BLOCK-MANUAL.md) | How a custom block is made: Blender, model formats, registration, Bedrock components, and why the two editions never share a build. |
| [custom_blocks/eye_block/README.md](custom_blocks/eye_block/README.md) | The Eye Block itself: its files, its property values, and how to change them. |

## Mods

| Module | Block | Editions | Status |
| --- | --- | --- | --- |
| [`custom_blocks/eye_block`](custom_blocks/eye_block) | `custom_blocks:eye_block` | Java and Bedrock | Java mod verified in game; Bedrock addon builds, not yet loaded |

## Repository layout

```
settings.gradle                Gradle multi-project, one include per mod
gradle.properties              every version, in one place
build.gradle                   root project, pins the wrapper version
gradle/mod-conventions.gradle  shared Java and packaging config
gradle/wrapper/                Gradle wrapper, committed
custom_blocks/<mod>/           one module per mod
images/                        original artwork
```

## Toolchain

| Component | Version |
| --- | --- |
| Minecraft Java Edition | 26.3 |
| Java | 25 |
| Fabric Loader | 0.19.5 |
| Fabric API | 0.161.0+26.3 |
| Fabric Loom | 1.17-SNAPSHOT |
| Gradle | 9.6.0 |
| Minecraft Bedrock Edition | 1.21 or later |

Every version above lives in `gradle.properties`. Change it there and nowhere else. `gradle/wrapper/gradle-wrapper.properties` carries the Gradle version separately, because the wrapper has to know it before Gradle starts.

### Why these versions look unfamiliar

Mojang moved Java Edition to year-based version numbers in 2026, so the `1.21.x` line was followed by `26.1`, `26.2` and `26.3`. Bedrock Edition still uses `1.21.x`. A tutorial written against `1.20` or `1.21` will differ from this repository in registration code, in resource paths, and in folder names.

### Why Mojang mappings

Minecraft ships obfuscated, so mod code is written against a mapping set. Fabric Loom and the Fabric documentation now default to Mojang official mappings, so class names here read `BlockBehaviour.Properties`, `BuiltInRegistries` and `Identifier`. Older tutorials use Yarn, where the same classes are `AbstractBlock.Settings`, `Registries` and `Identifier`. The two are not mixable inside one module.

## Setup

Java 25 is required. On Ubuntu:

```
sudo apt install -y openjdk-25-jdk
```

Gradle itself needs no install. The committed wrapper downloads 9.6.0 on first run.

## Building

Run a development client with the mod loaded:

```
./gradlew :custom_blocks:eye_block:runClient
```

Build the mod jar into `custom_blocks/eye_block/build/libs/`:

```
./gradlew :custom_blocks:eye_block:build
```

Build the two distributable files into `custom_blocks/<mod>/dist/`:

```
cd custom_blocks/eye_block && ./package.sh
```

`package.sh` always builds the `.mcaddon`, which needs only the Bedrock pack folders. It builds the `.mrpack` when the mod jar and the Fabric API jar are both present, and otherwise skips it with a message naming what is missing.

## Releasing

Attach both files to one release, so Java and Bedrock players use the same link:

```
gh release create v1.0.0 \
  custom_blocks/eye_block/dist/EyeBlock-1.0.0.mrpack \
  custom_blocks/eye_block/dist/EyeBlock-1.0.0.mcaddon \
  --notes "Eye Block 1.0.0"
```

Java players open the `.mrpack` with the Modrinth App, which installs Fabric Loader and copies the mods in. Bedrock players open the `.mcaddon`, which the game imports on its own.

Raise `mod_version` in `gradle.properties` and `PACK_VERSION` in the module's `pack.env` for each release, so player instances update cleanly rather than colliding.

## Conventions

Committed: source, assets, Bedrock packs, build scripts, the Gradle wrapper, and the original artwork under `images/`.

Not committed: build output, IDE files, each module's `dist/` output, and the third-party jars in `vendor/mods/`. See `.gitignore` for the exact patterns. A release carries the built artifacts, so the repository does not need to.

Fabric API is downloaded into `custom_blocks/<mod>/vendor/mods/` by hand and redistributed inside the `.mrpack`. Its Apache-2.0 license permits that.

## Adding another mod

1. Create `custom_blocks/<name>/` with `build.gradle`, `src/main/java` and `src/main/resources`.
2. Copy `build.gradle` from `eye_block` and change `archivesName`.
3. Add `include 'custom_blocks:<name>'` to `settings.gradle`.
4. Add a row to the Mods table above.

Shared build settings belong in `gradle/mod-conventions.gradle`, not in each module.

## License

MIT. See [LICENSE](LICENSE).
