minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i=1,#players do
		local pos = players[i]:getpos()
		local nodes = minetest.find_nodes_in_area_under_air({x=pos.x,y=pos.y-80,z=pos.z},{x=pos.x,y=pos.y+80,z=pos.z},{"group:cracky","group:crumbly","group:snappy"})
	end
end)

