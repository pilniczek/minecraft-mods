package com.example.customblocks;

import java.util.List;

import net.minecraft.resources.Identifier;
import net.minecraft.world.item.CreativeModeTabs;
import net.minecraft.world.level.block.Block;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.creativetab.v1.CreativeModeTabEvents;

public class CustomBlocks implements ModInitializer {
	public static final String MOD_ID = "custom_blocks";

	@Override
	public void onInitialize() {
		List<Block> buildingBlocks = ModBlocks.BUILDING_BLOCKS;

		CreativeModeTabEvents.modifyOutputEvent(CreativeModeTabs.BUILDING_BLOCKS).register(creativeTab -> {
			buildingBlocks.forEach(block -> creativeTab.accept(block.asItem()));
		});
	}

	public static Identifier id(String path) {
		return Identifier.fromNamespaceAndPath(MOD_ID, path);
	}
}
