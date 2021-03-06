local passive_only = false
spawnlite = {}
spawnlite.passive = {}
spawnlite.agressive = {}
spawnlite.water = {}
spawnlite.air = {}

spawnlite.mobs = {}
spawnlite.mobs.passive = {}
spawnlite.mobs.agressive = {}
spawnlite.mobs.water = {}
spawnlite.mobs.air = {}

spawnlite.mobs.passive.now = 0
spawnlite.mobs.agressive.now = 0
spawnlite.mobs.water.now = 0
spawnlite.mobs.air.now = 0

--MOB SPAWNING LIMITS
spawnlite.mobs.passive.max = 3
spawnlite.mobs.agressive.max = 5
spawnlite.mobs.water.max = 5
spawnlite.mobs.air.max = 5

local mobs = spawnlite.mobs


local function is_space(pos,size)
	local x,y,z = 1,0,0

	if size.x*size.y*size.z == 1 then
		return true
	end
	for i=2,size.x*size.y*size.z do
		if x > size.x-1 then
			x = 0
			y = y + 1
		end
		if y > size.y-1 then
			y = 0
			z = z + 1
		end
		if minetest.get_node({x=pos.x+x,y=pos.y+y,z=pos.z+z}).name ~= "air" then
			return false
		end
		x = x + 1
	end
	--[[
	local _, no_air = minetest.find_nodes_in_area(pos,{x=pos.x+size.x-1,y=pos.y+size.y-1,z=pos.z+size.z-1},{"air"}) 
	if no_air ~= size.x*size.y*size.z then
		return false
	else
		return true
	end
	--]]
	return true
end

local function get_new_mob(passive)
	if passive then
		return spawnlite.passive[math.random(1,#spawnlite.passive)]
	else
		return spawnlite.agressive[math.random(1,#spawnlite.agressive)]
	end
	return nil
end

--Spawning variables
local max_no = 1 --per player per spawn attempt

--Area variables
local width = 60
local half_width = width/2
local height = 80
local half_height = height/2

--Timing variables
local timer = 0
local spawn_interval = 1
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < spawn_interval then
		return
	end
	timer = 0
	local players = minetest.get_connected_players()
	local rand_x = math.random(0,width-1) - half_width
	local rand_z = math.random(0,width-1) - half_width
	local passive = passive_only or math.random(0,1) == 1
	for i=1,#players do
		local spawned = 0
		local pos = players[i]:getpos()
		local mob = get_new_mob(passive)
		local nodes = minetest.find_nodes_in_area_under_air(
			{x=pos.x+rand_x,y=pos.y-half_height,z=pos.z+rand_z}
			,{x=pos.x+rand_x,y=pos.y+half_height,z=pos.z+rand_z}
			,mob.nodes)
		for i=1,#nodes do
			--Spawn limit conditions
			if spawned > max_no then
				break
			end
			if passive and mobs.passive.now > mobs.passive.max then
				return
			elseif not passive and mobs.agressive.now > mobs.agressive.max then
				return
			end
			if mobs[mob.name].now > mobs[mob.name].max_no then
				break
			end

			--Tests to check that placement suitiability for mob
			local lightlevel = minetest.get_node_light(
				{x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z})
			if lightlevel >= mob.min_light 
			and lightlevel <= mob.max_light
			and nodes[i].y > mob.min_height
			and nodes[i].y < mob.max_height 
			and is_space({x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z},mob.size) then
				--chance reduce overall mob spawn rate, but is useful for the programmer
				if not mob.chance then
					minetest.add_entity({x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z},mob.name)
					mobs[mob.name].now = mobs[mob.name].now + 1
					if passive then
						mobs.passive.now = mobs.passive.now + 1
					else
						mobs.agressive.now = mobs.agressive.now + 1
					end
					spawned = spawned + 1
				elseif math.random(1,1000) < mob.chance * 10 then
					minetest.add_entity({x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z},mob.name)
					mobs[mob.name].now = mobs[mob.name].now + 1
					if passive then
						mobs.passive.now = mobs.passive.now + 1
					else
						mobs.agressive.now = mobs.agressive.now + 1
					end
					spawned = spawned + 1
				end
			end
		end
	end
end)

local mob_count_timer = 0
local moblist_update_time = 5
minetest.register_globalstep(function(dtime)
	mob_count_timer = mob_count_timer + dtime
	if mob_count_timer < moblist_update_time then
		return
	end
	mob_count_timer = 0
	for k,v in pairs(spawnlite.mobs) do
		v.now = 0
	end
	for k,v in pairs(minetest.luaentities) do
		if v.name and mobs[v.name] then
			mobs[v.name].now = mobs[v.name].now + 1
		end
	end
	for i=1,#spawnlite.passive do
		mobs.passive.now = mobs.passive.now + spawnlite.passive[i].now
	end
	for i=1,#spawnlite.agressive do
		mobs.agressive.now = mobs.agressive.now + spawnlite.agressive[i].now
	end
	--[[
	for k,v in pairs(minetest.luaentities) do
		minetest.debug(k)
		minetest.debug(v.name)
	end
	--]]
end)

local function get_mob_size(def)
	local size = {}
	local box = def.collisionbox
	size.x = math.ceil(math.abs(box[1] - box[4]))
	size.y = math.ceil(math.abs(box[2] - box[5]))
	size.z = math.ceil(math.abs(box[3] - box[6]))

	return size
end

local function get_mob_group(def,nodes)
	if def.group then
		return def.group
	elseif nodes[1] == "air" then
		return "air"
	elseif nodes[1] == "default:water" then
		return "water"
	elseif def.type == "monster" then
		return "agressive"
	else
		return "passive"
	end
	return nil
end

spawnlite.register_specific = function(name,nodes,ignored_neighbors,min_light
	,max_light,ignored_interval,chance_percent_1dp,max_no,min_height
	,max_height,group)

	local mob = {}
	spawnlite.mobs[name] = spawnlite.mobs[name] or mob
	--Setup Mob Specific table
	mob.name = name
	mob.nodes = nodes
	mob.min_light = min_light or 0
	mob.max_light = max_light or 16
	mob.chance = chance_percent_1dp
	mob.max_no = max_no or 5
	mob.now = 0
	mob.min_height = min_height or -33000
	mob.max_height = max_height or 33000
	--Setup variables from mob def
	local mob_def = minetest.registered_entities[name]
	mob.size = get_mob_size(mob_def)
	mob.group = group or get_mob_group(mob_def,nodes)

	--Setup group table
	table.insert(spawnlite[mob.group],spawnlite.mobs[name])
end

dofile(minetest.get_modpath("spawnlite").."/mobs/init.lua")
