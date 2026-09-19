# Java Edition block API, Minecraft 26.3

Verified against a running 26.3 client with Fabric Loader 0.19.5 and Fabric API 0.161.0+26.3.

Contents: mappings, registration, properties, version differences, resource file contents.

## Mappings

This repository uses Mojang official mappings, which is what Fabric Loom and the Fabric documentation now default to. Loom applies them without a `mappings` line in `build.gradle`.

Yarn-mapped snippets found online will not compile here. The most common collisions:

| Yarn | Mojang |
| --- | --- |
| `AbstractBlock.Settings` | `BlockBehaviour.Properties` |
| `Registries.BLOCK` | `BuiltInRegistries.BLOCK` |
| `BlockSoundGroup` | `SoundType` |
| `.luminance(...)` | `.lightLevel(...)` |
| `.requiresTool()` | `.requiresCorrectToolForDrops()` |
| `ItemGroups` / `ItemGroupEvents` | `CreativeModeTabs` / `CreativeModeTabEvents` |

Do not mix the two sets inside one module.

## Registration

26.2 separated block ids from item ids. A block that has a matching item is identified by a `BlockItemId` carrying both keys, and the properties object must be given its id before the block is constructed, or registration throws at startup.

```java
package com.example.customblocks;

import java.util.function.Function;

import net.minecraft.core.Registry;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.references.BlockItemId;
import net.minecraft.resources.Identifier;
import net.minecraft.resources.ResourceKey;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.CreativeModeTabs;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.material.MapColor;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.creativetab.v1.CreativeModeTabEvents;

public class CustomBlocks implements ModInitializer {
	public static final String MOD_ID = "custom_blocks";

	public static final BlockItemId EYE_BLOCK_ID = BlockItemId.create(id("eye_block"), id("eye_block"));

	public static final Block EYE_BLOCK = register(
			EYE_BLOCK_ID,
			Block::new,
			BlockBehaviour.Properties.of()
					.strength(1.5F, 6.0F)
					.sound(SoundType.STONE)
					.mapColor(MapColor.QUARTZ)
					.lightLevel(state -> 7)
					.requiresCorrectToolForDrops()
	);

	@Override
	public void onInitialize() {
		CreativeModeTabEvents.modifyOutputEvent(CreativeModeTabs.BUILDING_BLOCKS).register(creativeTab -> {
			creativeTab.accept(EYE_BLOCK.asItem());
		});
	}

	public static Identifier id(String path) {
		return Identifier.fromNamespaceAndPath(MOD_ID, path);
	}

	private static Block register(ResourceKey<Block> id, Function<BlockBehaviour.Properties, Block> blockFactory, BlockBehaviour.Properties properties) {
		Block block = blockFactory.apply(properties.setId(id));
		return Registry.register(BuiltInRegistries.BLOCK, id, block);
	}

	private static Block register(BlockItemId id, Function<BlockBehaviour.Properties, Block> blockFactory, BlockBehaviour.Properties properties) {
		Block block = register(id.block(), blockFactory, properties);
		BlockItem blockItem = new BlockItem(block, new Item.Properties()
				.useBlockDescriptionPrefix()
				.setId(id.item()));
		Registry.register(BuiltInRegistries.ITEM, id.item(), blockItem);
		return block;
	}
}
```

The two `register` overloads are worth keeping even for a single block: the `ResourceKey` one handles blocks with no item, and the `BlockItemId` one delegates to it. `useBlockDescriptionPrefix()` is what keeps the translation key at `block.<modid>.<name>` instead of an item key.

The block factory is a `Function`, so a block with its own class passes `MyBlock::new`, and one needing constructor arguments passes a lambda such as `settings -> new StairBlock(BASE.defaultBlockState(), settings)`.

## Properties

| Call | Effect |
| --- | --- |
| `.strength(hardness, resistance)` | Dig time and blast resistance. Stone is `1.5F, 6.0F`, sand `0.5F`. |
| `.sound(SoundType.X)` | Step, break and place sounds. |
| `.mapColor(MapColor.X)` | Colour on maps. A fixed enum, so an arbitrary hex value cannot be expressed. |
| `.lightLevel(state -> n)` | Emitted light, 0 to 15. |
| `.requiresCorrectToolForDrops()` | Drops nothing when broken by hand. Pair with a `needs_<tier>_tool` tag. |
| `.noOcclusion()` | For glass-like and leaf-like blocks. |
| `.randomTicks()` | The block needs random ticks. |
| `.noLootTable()` | Never drops, and no loot table file is expected. |
| `.pushReaction(PushReaction.DESTROY)` | Piston behaviour. |
| `.instrument(NoteBlockInstrument.X)` | Note block sound when placed underneath. |
| `.ofFullCopy(Blocks.X)` | Copy a vanilla block's whole property set as a starting point. |

## What earlier versions did differently

| Change | Before | 26.3 |
| --- | --- | --- |
| Version numbering | `1.20.x`, `1.21.x` | `26.1`, `26.2`, `26.3` |
| Registration | `Registry.register(registry, id, block)` | `properties.setId(id)` first, `BlockItemId` for blocks with items, since 26.2 |
| Settings registry key | `AbstractBlock.Settings.registryKey(key)` in 1.21.2 to 26.1 | folded into `setId` |
| Item model | `models/item/<name>.json`, a plain model | `items/<name>.json`, an item model definition, since 1.21.4 |
| Loot table folder | `loot_tables/` | `loot_table/`, renamed in 1.21 |
| Block tag folder | `tags/blocks/` | `tags/block/`, renamed in 1.21 |
| Block codecs | every block class defined a `Codec` | removed in 26.3, with the `block_type` registry |

The codec removal matters when porting a falling block or any other vanilla subclass: guidance about supplying a `CODEC` no longer applies.

## Resource file contents

Block model, plain cube:

```json
{
  "parent": "minecraft:block/cube_all",
  "textures": { "all": "<modid>:block/<block>" }
}
```

Blockstate, no state properties:

```json
{
  "variants": { "": { "model": "<modid>:block/<block>" } }
}
```

Item model definition. This selects a model rather than being one, which is why it is not interchangeable with the block model:

```json
{
  "model": {
    "type": "minecraft:model",
    "model": "<modid>:block/<block>"
  }
}
```

Loot table that drops the block itself:

```json
{
  "type": "minecraft:block",
  "pools": [
    {
      "rolls": 1,
      "entries": [{ "type": "minecraft:item", "name": "<modid>:<block>" }],
      "conditions": [{ "condition": "minecraft:survives_explosion" }]
    }
  ]
}
```

Tool tag, merging with vanilla rather than replacing it:

```json
{ "replace": false, "values": ["<modid>:<block>"] }
```

Since 1.21.4 the game draws no distinction between block models and item models, so `models/block/` and `models/item/` are organisational only. The item model definition under `items/` is the real dividing line.

## Toolchain

Versions live in the repository root `gradle.properties` and nowhere else: Minecraft 26.3, Fabric Loader 0.19.5, Fabric API 0.161.0+26.3, Loom 1.17-SNAPSHOT, Gradle 9.6.0, Java 25. `fabric.mod.json` takes `${version}` from `mod_version` at build time.
