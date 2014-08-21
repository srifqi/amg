amg.hud = {}

local bedrock_timer = 0
minetest.register_globalstep(function(dtime)
	if dtime < 0.1 then return end
	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = player:getpos()
		local name = player:get_player_name()
		
		local base = minetest.get_perlin(1234, 6, 0.5, 256):get2d({x=pos.x,y=pos.z})
		local moun = minetest.get_perlin(4321, 6, 0.5, 256):get2d({x=pos.x,y=pos.z})
		local base = math.ceil((base * -30) + wl + 10 + (moun * 15))
		local temp = 0
		local humi = 0
		if base > 95 then
			temp = 0.05
			humi = 0.9
		else
			temp = minetest.get_perlin(5678, 7, 0.5, 512):get2d({x=pos.x,y=pos.z})
			humi = minetest.get_perlin(8765, 7, 0.5, 512):get2d({x=pos.x,y=pos.z})
		end
		
		local biometext = biome.get_by_temp_humi(math.abs(temp*2),math.abs(humi*100))[2]
		
		if not amg.hud[name] then
			amg.hud[name] = {}
			
			amg.hud[name].BiomeId = player:hud_add({
				hud_elem_type = "text",
				name = "Biome",
				number = 0xFFFFFF,
				position = {x=1, y=1},
				offset = {x=-130, y=-80},
				direction = 0,
				text = "Biome: "..biometext,
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			
			amg.hud[name].oldBiome = biometext
			return
		elseif amg.hud[name].oldBiome ~= biometext then
			player:hud_change(amg.hud[name].BiomeId, "text",
				"Biome: "..biometext)
			amg.hud[name].oldBiome = biometext
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	amg.hud[player:get_player_name()] = nil
end)