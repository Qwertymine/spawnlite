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


local function spawn_mob(pos,name,group)
	minetest.add_entity(pos,name)
	mobs[name].now = mobs[name].now + 1
	mobs[group].now = mobs[group].now + 1
end


local function in_group(pos,mob)
	local node = minetest.get_node(pos)
	for i=1,#mob.nodes do
		if node.name == mob.nodes[i] 
		or minetest.get_item_group(node.name,mob.nodes[i]) ~= 0 then
			minetest.chat_send_all("spawned?")
			return true
		end
	end
	return false
end


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
local segments = 3
local segment_height = math.ceil(height/segments)

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
	local passive = passive_only or math.random(0,1) == 1
	for i=1,#players do
		local spawned = 0
		local pos = players[i]:getpos()
		pos.x = pos.x - half_width + math.random(0,width-1)
		pos.z = pos.z - half_width + math.random(0,width-1)
		local mob = get_new_mob(passive)
		local this_segment = pos.y + half_height
		local next_segment = pos.y + half_height - segment_height
		for i=1,segments do
			local search_top = math.random(next_segment+1,this_segment)
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

			--try to find next node
			local los,node_pos = minetest.line_of_sight({x=pos.x,y=search_top,z=pos.z},{x=pos.x,y=pos.y-half_height,z=pos.z})
			--NONE FOUND
			if los then
				--IF I ADD SEARCH CANCELLING THERE MAY NEED TO BE 
				--A SPECIAL SPAWN FUNCTION HERE
				break
			end
			--BLOCKED BY STARTING NODE - NO AIR
			--node_pos.y = math.floor(node_pos.y)
			if node_pos.y == search_top then
				--TODO TRY SPAWN GROUND/WATER
			--CHEAP MOB FAIL CONDITIONS
			elseif node_pos.y < mob.min_height then
				break
			elseif node_pos.y > mob.max_height then
				if pos.y - half_height > mob.max_height then
					break
				end
			elseif (mob.size.x * mob.size.z == 1 and mob.size.y < search_top - node_pos.y)
			or is_space({x=pos.x,y=node_pos.y+1,z=pos.z},mob.size) then
				local lightlevel = minetest.get_node_light(
					{x=pos.x,y=node_pos.y+1,z=pos.z})
				if lightlevel
				and lightlevel >= mob.min_light 
				and lightlevel <= mob.max_light
				and in_group(node_pos,mob) then
					--chance reduce overall mob spawn rate, but is useful for the programmer if not mob.chance then
					if not mob.chance then
						spawn_mob({x=pos.x,y=node_pos.y+1,z=pos.z},mob.name,mob.group)
						spawned = spawned + 1
					elseif math.random(1,1000) < mob.chance * 10 then
						spawn_mob({x=pos.x,y=node_pos.y+1,z=pos.z},mob.name,mob.group)
						spawned = spawned + 1
					end
				end
			end
			--Varible setup for next segment
			next_segment = next_segment - segment_height
			if node_pos.y < next_segment + segment_height then
				this_segment = node_pos.y
				while next_segment > this_segment do
					next_segment = next_segment - segment_height
				end
				if next_segment < pos.y - half_height then
					next_segment = pos.y - half_height
				end
			else
				this_segment = next_segment + segment_height
			end
			if this_segment <= pos.y - height then
				break
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
dofile(minetest.get_modpath("spawnlite").."/infotools.lua")
