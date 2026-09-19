# minecraft-mods

Custom Minecraft blocks, built for both editions from one source of art.

Each mod lives in its own module and produces two shippable files: a `.mrpack` modpack for Java Edition players using the Modrinth App, and a `.mcaddon` for Bedrock Edition players. Both are attached to GitHub releases.

## Mods

| Module | Block | Editions |
| --- | --- | --- |
| [`custom_blocks/eye_block`](custom_blocks/eye_block) | `custom_blocks:eye_block` | Java and Bedrock |

## Repository layout

```
settings.gradle              Gradle multi-project, one entry per mod
gradle.properties            every version, in one place
gradle/mod-conventions.gradle  shared Java and packaging config
custom_blocks/<mod>/         one module per mod
images/                      original artwork
CUSTOM-BLOCK-MANUAL.md       how custom blocks are made, start to finish
```

## Target versions

| Component | Version |
| --- | --- |
| Minecraft Java Edition | 26.3 |
| Java | 25 |
| Fabric Loader | 0.19.5 |
| Fabric API | 0.161.0+26.3 |
| Fabric Loom | 1.17-SNAPSHOT |
| Gradle | 9.6.0 |
| Minecraft Bedrock Edition | 1.21 or later |

Mojang moved Java Edition to year-based version numbers in 2026, so `1.21.x` was followed by `26.1`, `26.2` and `26.3`. Bedrock Edition still uses `1.21.x`.

Mods are written against Mojang official mappings, which is what Fabric Loom and the Fabric documentation now default to.

Every version above lives in `gradle.properties`. Change it there and nowhere else.

## Building

```
./gradlew :custom_blocks:eye_block:runClient
./gradlew :custom_blocks:eye_block:build
```

Then build the distributable files:

```
cd custom_blocks/eye_block && ./package.sh
```

Building needs a JDK 25. The Gradle wrapper pulls Gradle 9.6.0 on first run.

## Adding another mod

1. Create `custom_blocks/<name>/` with `build.gradle`, `src/main/java` and `src/main/resources`.
2. Copy `build.gradle` from `eye_block` and change `archivesName`.
3. Add `include 'custom_blocks:<name>'` to `settings.gradle`.
4. Add a row to the Mods table above.

Shared build settings belong in `gradle/mod-conventions.gradle`, not in each module.

## License

MIT. See [LICENSE](LICENSE).
