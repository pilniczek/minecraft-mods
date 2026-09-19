---
name: minecraft-block
description: Add, change or debug a custom block in this repository, for Minecraft Java Edition 26.3 with Fabric and Mojang mappings and for Bedrock Edition addons. Use this skill whenever the user wants a new block, wants to change how an existing block behaves (hardness, light, sound, drops, tool, texture, shape), wants a block ported between the two editions, or is debugging a block that does not appear, renders as missing-texture purple and black, drops nothing, or fails registration at startup. Use it even when the user only says "add a block" or names a block idea without mentioning Minecraft versions, Fabric, mappings or Bedrock, because the version-specific details are exactly what is easy to get wrong here.
---

# Adding a custom block

This repository ships each block twice, because Java Edition and Bedrock Edition share nothing but the texture PNG. Java needs compiled Java against the Fabric API; Bedrock needs two JSON packs and no code. Build both halves or say explicitly which one you are skipping.

Read `CUSTOM-BLOCK-MANUAL.md` at the repository root for the underlying concepts. This skill is the checklist for doing it in this repository.

## Why the version matters so much

Minecraft Java Edition moved to year-based version numbers in 2026, so `1.21.x` was followed by `26.1`, `26.2` and `26.3`. Almost every block tutorial online predates that, and copied code fails in ways that are hard to read: a registration crash at startup, a silently missing item model, a loot table the game never finds.

Before writing Java, read `references/java-api.md`. It has the exact registration shape for 26.3 and a table of what older versions did differently. Treat any snippet found elsewhere as suspect until checked against it.

For the Bedrock half, read `references/bedrock.md`.

## Work in this order

The texture is the only shared asset, so it comes first and lives in exactly one place.

1. **Place the source texture** at `custom_blocks/<block>/art/<block>.png`. Use 16x16, or another power of two. Minecraft renders block textures with a nearest-neighbour filter, so any blur baked into the source stays visible.
2. **Record the intent** in `custom_blocks/<block>/spec.json`. Nothing reads this file; it exists so the Java and Bedrock halves can be checked against one description rather than against each other, which is how they drift apart.
3. **Write the Java half** using `references/java-api.md`.
4. **Write the Bedrock half** using `references/bedrock.md`.
5. **Sync the texture** with `./build.sh` in the module, which copies it into both halves. Never copy it by hand, or the two go out of step.
6. **Register the module** in the repository root `settings.gradle` with `include 'custom_blocks:<block>'`, and give it a `build.gradle` copied from `eye_block` with `archivesName` changed.
7. **Verify in game** using the checklist below.

## Java files for one block

Every path below is under `custom_blocks/<block>/src/main/resources/`, with `<modid>` being the module's namespace.

| Path | Purpose |
| --- | --- |
| `assets/<modid>/textures/block/<block>.png` | Written by `build.sh`, not by hand. |
| `assets/<modid>/models/block/<block>.json` | `"parent": "minecraft:block/cube_all"` plus a `textures.all` entry for a plain cube. |
| `assets/<modid>/items/<block>.json` | Item model definition. A different format from the model above, and not under `models/item/`. |
| `assets/<modid>/blockstates/<block>.json` | Maps states to models; a stateless block has one empty-string variant. |
| `assets/<modid>/lang/en_us.json` | `block.<modid>.<block>` gives the display name. |
| `data/<modid>/loot_table/blocks/<block>.json` | Without this the block drops nothing when broken. |
| `data/minecraft/tags/block/mineable/<tool>.json` | Which tool digs it quickly. |
| `data/minecraft/tags/block/needs_<tier>_tool.json` | Only if the block requires a tool tier. |

`loot_table` and `tags/block` are singular. They were renamed from the plural forms in 1.21, and stale documentation still shows `loot_tables` and `tags/blocks`. A plural directory is simply never read, and the failure is silent.

## Verifying in game

Run `./gradlew :custom_blocks:<block>:runClient` from the repository root, then check each of these, because each one fails independently and for a different reason:

- The block appears in its creative tab **and** shows a real name, not a raw `block.<modid>.<block>` key. A raw key means the lang file did not load.
- `/give @s <modid>:<block>` works. If the tab entry is missing but the give works, the creative tab hook did not fire; if neither works, registration failed.
- Placed, it shows the texture on every intended face. Purple and black checkers mean the model's texture reference or the blockstate's model reference is wrong.
- The item icon in the hotbar renders. A broken icon points at the item model definition under `items/`.
- Any light level actually lights a dark space.
- Breaking it with the intended tool drops the block, and breaking it by hand drops nothing when the block requires a tool.

Watch the console during placement for `Unable to load model`, which names the exact path that failed.

## Common failures and what they mean

| Symptom | Cause |
| --- | --- |
| Crash at startup naming a block id | The properties object was not given its id before the block was constructed. See `references/java-api.md`. |
| Purple and black checkers | Texture path in the model JSON, or the model path in the blockstate JSON, does not resolve. |
| Item shows as a broken icon | Missing or misplaced item model definition under `assets/<modid>/items/`. |
| Block drops nothing | Loot table missing, or written into `loot_tables/` rather than `loot_table/`. |
| Raw translation key as the name | Lang file missing the key, or the namespace directory is misspelled. |
| Block missing from the creative tab | The creative tab event was not registered in the initializer. |
| Bedrock block missing after import | Manifest UUIDs collide with another pack, or the behaviour pack does not depend on the resource pack. |
