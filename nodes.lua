minetest.register_node("amg:bedrock", {
	description = "amg's BEDROCK",
	tiles ={"default_cobble.png"},
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_stone_defaults()
})

minetest.register_node("amg:dirt_at_savanna", {
	description = "Dirt with Grass at Savanna",
	tiles = {"amg_savanna_grass.png", "default_dirt.png", "default_dirt.png^amg_savanna_grass_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,soil=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})