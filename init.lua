local timer = 0
local passive_only = false
spawnlite = {}
spawnlite.passive = {{name = "boats:boat",size = {x=2,y=1,z=2}}}
spawnlite.agressive = {{name = "boats:boat",size = {x=1,y=1,z=1}}}

local function is_space(pos,size)
	local x,y,z = 1,0,0
	if size.x*size.y*size.z == 1 then
		return true
	end
	for i=2,size.x*size.y*size.z do
		if x > size.x then
			x = 0
			y = y + 1
		end
		if y > size.y then
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

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 1 then
		return
	end
	timer = 0
	local players = minetest.get_connected_players()
	local rand_x = math.random(0,19) - 10
	local rand_z = math.random(0,19) - 10
	for i=1,#players do
		local pos = players[i]:getpos()
		local nodes = minetest.find_nodes_in_area_under_air({x=pos.x+rand_x,y=pos.y-80,z=pos.z+rand_z}
			,{x=pos.x+rand_x,y=pos.y+80,z=pos.z+rand_z},{"group:cracky","group:crumbly","group:snappy"})
		for i=1,#nodes do
			local lightlevel = minetest.get_node_light({x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z})
			local mob = nil
			if lightlevel < 8 then
				if passive_only then
					break
				end
				mob = spawnlite.agressive[math.random(1,#spawnlite.agressive)]
			else
				if minetest.get_node(nodes[i]).name ~= "default:sand" then
					break
				end
				mob = spawnlite.passive[math.random(1,#spawnlite.passive)]
			end
			if is_space({x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z},mob.size) then
				minetest.add_entity({x=pos.x+rand_x,y=nodes[i].y+1,z=pos.z+rand_z},mob.name)
			end
		end
	end
end)

