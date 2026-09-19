# Bedrock Edition addon blocks

Bedrock keeps its own `1.21.x` numbering; the year-based scheme is Java Edition only. Block `format_version` 1.21.0 is stable, so custom blocks need no experimental toggle.

An addon is two packs and no compiled code. The behaviour pack defines the block; the resource pack supplies how it looks and sounds.

## Layout

```
custom_blocks/<block>/bedrock/
  <block>_bp/
    manifest.json
    blocks/<block>.json
  <block>_rp/
    manifest.json
    blocks.json
    texts/en_US.lang
    textures/terrain_texture.json
    textures/blocks/<block>.png
```

`build.sh` writes the PNG. Everything else is hand-written.

## Manifests

Each pack needs its own `header.uuid` and its own module `uuid`, four distinct UUIDs across the two packs. Generate them, never copy them from another pack, because a collision makes one pack silently replace the other in the player's game.

The behaviour pack lists the resource pack's **header** UUID under `dependencies`, so importing one pulls in the other.

```json
{
  "format_version": 2,
  "header": {
    "name": "<Block> Behavior",
    "description": "...",
    "uuid": "<uuid-1>",
    "version": [1, 0, 0],
    "min_engine_version": [1, 21, 0]
  },
  "modules": [
    { "type": "data", "uuid": "<uuid-2>", "version": [1, 0, 0] }
  ],
  "dependencies": [
    { "uuid": "<resource pack header uuid>", "version": [1, 0, 0] }
  ]
}
```

The resource pack manifest is the same shape with `"type": "resources"` and no `dependencies`.

## The block

```json
{
  "format_version": "1.21.0",
  "minecraft:block": {
    "description": {
      "identifier": "<modid>:<block>",
      "menu_category": {
        "category": "construction",
        "group": "minecraft:itemGroup.name.stone"
      }
    },
    "components": {
      "minecraft:geometry": "minecraft:geometry.full_block",
      "minecraft:material_instances": {
        "*": { "texture": "<block>", "render_method": "opaque" }
      },
      "minecraft:destructible_by_mining": {
        "seconds_to_destroy": 1.5,
        "item_specific_speeds": [
          { "item": "minecraft:stone_pickaxe", "destroy_speed": 0.6 }
        ]
      },
      "minecraft:destructible_by_explosion": { "explosion_resistance": 6 },
      "minecraft:light_emission": 7,
      "minecraft:map_color": "#efefef"
    }
  }
}
```

The `texture` value is a **key**, not a path. `terrain_texture.json` binds that key to the file:

```json
{
  "resource_pack_name": "<block>_rp",
  "texture_name": "atlas.terrain",
  "padding": 8,
  "num_mip_levels": 4,
  "texture_data": {
    "<block>": { "textures": "textures/blocks/<block>" }
  }
}
```

A missing or misspelled key here is the usual cause of an untextured Bedrock block, and it fails quietly.

`blocks.json` assigns the sound set, and `texts/en_US.lang` the name:

```
tile.<modid>:<block>.name=<Block>
```

## Components worth knowing

| Component | Effect |
| --- | --- |
| `minecraft:destructible_by_mining` | Base `seconds_to_destroy` plus per-tool speeds. |
| `minecraft:destructible_by_explosion` | Blast resistance. |
| `minecraft:light_emission` | 0 to 15. |
| `minecraft:material_instances` | Texture key and render method: `opaque`, `alpha_test` for cut-outs, `blend` for translucency. |
| `minecraft:geometry` | `minecraft:geometry.full_block`, or a geometry file exported from Blockbench into `<block>_rp/models/blocks/`. |
| `minecraft:loot` | Path to a loot table; custom blocks drop themselves by default. |
| `minecraft:collision_box` / `minecraft:selection_box` | Non-cube hitboxes. |

## Where Bedrock cannot match Java

Bedrock has no equivalent of the Java `needs_<tier>_tool` tag. Tool tier gating is approximated by per-tool destroy speeds, and a hard requirement needs a `minecraft:loot` component pointing at a loot table with tool conditions.

Map colour is a free hex value on Bedrock and a fixed enum on Java, so the two can only ever be close. `spec.json` records them separately for that reason.

## Property mapping

| Intent | Java | Bedrock |
| --- | --- | --- |
| Hardness | `.strength(a, b)` | `destructible_by_mining.seconds_to_destroy` |
| Blast resistance | second argument of `.strength` | `destructible_by_explosion.explosion_resistance` |
| Light | `.lightLevel(state -> n)` | `light_emission` |
| Texture binding | the model's `textures` map | `terrain_texture.json` plus `material_instances` |
| Shape | `elements` in the model JSON | a geometry file plus `minecraft:geometry` |
| Sound | `.sound(SoundType.X)` | `blocks.json` sound entry |
| Name | `lang/en_us.json` | `texts/en_US.lang` |
| Creative tab | `CreativeModeTabEvents` in code | `description.menu_category` |

## Testing

`./package.sh` in the module builds `dist/<Name>-<version>.mcaddon`, which is the two pack folders zipped with the pack directories at the archive root. Opening that file imports both packs; they still have to be enabled per world.

For a shared world, apply the packs to a Realm or list them in a dedicated server's `world_behavior_packs.json` and `world_resource_packs.json`, and joining clients download them automatically.
