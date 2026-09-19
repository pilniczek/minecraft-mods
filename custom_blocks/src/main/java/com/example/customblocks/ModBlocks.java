package com.example.customblocks;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

import net.minecraft.core.Registry;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.references.BlockItemId;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.material.MapColor;

public final class ModBlocks {
	public static final List<Block> BUILDING_BLOCKS = new ArrayList<>();

	public static final Block EYE_BLOCK = register(
			"eye_block",
			BUILDING_BLOCKS,
			Block::new,
			BlockBehaviour.Properties.of()
					.strength(1.5F, 6.0F)
					.sound(SoundType.STONE)
					.mapColor(MapColor.QUARTZ)
					.lightLevel(state -> 7)
					.requiresCorrectToolForDrops()
	);

	private ModBlocks() {
	}

	private static Block register(
			String name,
			List<Block> creativeTab,
			Function<BlockBehaviour.Properties, Block> blockFactory,
			BlockBehaviour.Properties properties
	) {
		BlockItemId id = BlockItemId.create(CustomBlocks.id(name), CustomBlocks.id(name));

		Block block = blockFactory.apply(properties.setId(id.block()));
		Registry.register(BuiltInRegistries.BLOCK, id.block(), block);

		BlockItem blockItem = new BlockItem(block, new Item.Properties().useBlockDescriptionPrefix().setId(id.item()));
		Registry.register(BuiltInRegistries.ITEM, id.item(), blockItem);

		creativeTab.add(block);
		return block;
	}
}
