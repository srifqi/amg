amg = amg or {}
amg.seed = nil

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
	amg.seed = mgparams.seed
end)

--param?
wl = 63

biome = {}
tree = {}
dofile(minetest.get_modpath(minetest.get_current_modname()).."/nodes.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/trees.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/biomemgr.lua")

local function get_perlin_map(seed, octaves, persistance, scale, minp, maxp)
	local sidelen = maxp.x - minp.x +1
	local pm = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=scale, y=scale, z=scale}, seed=seed, octaves=octaves, persist=persistance},
		{x=sidelen, y=sidelen, z=sidelen}
	)
	return pm:get2dMap_flat({x = minp.x, y = minp.z, z = 0})
end

--node id?
local gci = minetest.get_content_id
local c_air = gci("air")
local c_bedrock = gci("amg:bedrock")
local c_lava_source = gci("default:lava_source")

local function amg_generate(minp, maxp, seed, vm, emin, emax)
	local t1 = os.clock()
	local pr = PseudoRandom(seed)
	print("[amg]:"..minp.x..","..minp.y..","..minp.z)
	local area = VoxelArea:new{
		MinEdge={x=emin.x, y=emin.y, z=emin.z},
		MaxEdge={x=emax.x, y=emax.y, z=emax.z},
	}
	local data = vm:get_data()
	local sidelen = maxp.x - minp.x + 1
	local base = get_perlin_map(1234, 6, 0.5, 256, minp, maxp) -- base height
	local moun = get_perlin_map(4321, 6, 0.5, 256, minp, maxp) -- addition
	local temp = get_perlin_map(5678, 7, 0.5, 512, minp, maxp) -- temperature (0-2)
	local humi = get_perlin_map(8765, 7, 0.5, 512, minp, maxp) -- humidity (0-100)
	local cave = minetest.get_perlin(3456, 6, 0.5, 360) -- cave
	--local laca = minetest.get_perlin(1278, 6, 0.5, 360) -- lava cave
	local nizx = 0
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		nizx = nizx + 1
		local base_ = math.ceil((base[nizx] * -30) + wl + 10 + (moun[nizx] * 15))
		local temp_ = 0
		local humi_ = 0
		if base_ > 95 then
			temp_ = 0.10
			humi_ = 90
		else
			temp_ = math.abs(temp[nizx] * 2)
			humi_ = math.abs(humi[nizx] * 100)
		end
		--print(x..","..z.." : "..temp_)
		for y_ = minp.y, maxp.y do
			local vi = area:index(x,y_,z)
			-- world height limit :(
			if y_ < 0 or y_ > 255 then
				data[vi] = c_air
			elseif y_ == 0 then
				data[vi] = c_bedrock
			--
			-- cave
			elseif math.abs(cave:get3d({x=x,y=y_,z=z})) < 0.005 then
				data[vi] = c_air
			--]]
			--[[
			-- lava cave
			elseif math.abs(laca:get3d({x=x,y=y_,z=z})) > 350 and y_ < wl * 2/3 then
				data[vi] = c_lava_source
			--]]
			-- biome
			else
				data[vi] = biome.get_block_by_temp_humi(temp_, humi_, base_, wl, y_, x, z)
			end
		end
		
	end
	end
	
	--tree planting
	local nizx = 0
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		nizx = nizx + 1
		local base_ = math.ceil((base[nizx] * -30) + wl + 10 + (moun[nizx] * 15))
		local temp_ = 0
		local humi_ = 0
		if base_ > 95 then
			temp_ = 0.10
			humi_ = 90
		else
			temp_ = math.abs(temp[nizx] * 2)
			humi_ = math.abs(humi[nizx] * 100)
		end
		local biome__ = biome.list[biome.get_by_temp_humi(temp_,humi_)[1]]
		local tr = biome__.trees
		local filled = false
		--print("done. "..biome__.name.." Biome. spawning "..#tr.." type of floras ...")
		for i = 1, #tr do
			if filled == true then break end
			local tri = tree.registered[tr[i][1]] or tree.registered["nil"]
			local chance = tr[i][2] or 1024
			--[[
			print(
				"try to spawn "..tr[i][1]..
				" at "..x..","..(base_+1)..","..z..
				" in "..biome__.name.." biome"
			)
			--]]
			if
				pr:next(1,chance) == 1 and
				base_+1 >= tri.minh and base_+1 <= tri.maxh and
				data[area:index(x,base_,z)] == gci(tri.grows_on)
			then
				tree.spawn({x=x,y=base_+1,z=z},tr[i][1],data,area,seed,minp,maxp,pr)
				filled = true
				--[[
				print(
					"spawned "..tr[i][1]..
					" at "..x..","..(base_+1)..","..z..
					" in "..biome__.name.." biome"
				)
				--]]
			end
		end
	end
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:update_liquids()
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 100000)/100
	print("[amg]:Done in "..chugent.."ms")
end

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > 256 or maxp.y < 0 then return end
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	amg_generate(minp, maxp, seed, vm, emin, emax)
end)

dofile(minetest.get_modpath(minetest.get_current_modname()).."/hud.lua")