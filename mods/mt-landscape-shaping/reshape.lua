
local rng = PseudoRandom(os.time())

local air_content_id , fire_content_id
local block_water_source_content_id , water_source_content_id , water_flowing_content_id
local block_river_water_source_content_id , river_water_source_content_id , river_water_flowing_content_id
local block_lava_source_content_id , lava_source_content_id , lava_flowing_content_id



-- It is possible for node to record here the chance for a drop to preserved
landscape_shaping.drop_chance = {}



local content_id_data = {}

minetest.register_on_mods_loaded( function() 
	air_content_id = minetest.get_content_id("air")
	fire_content_id = minetest.get_content_id("fire:basic_flame")

	water_source_content_id = minetest.get_content_id("default:water_source")
	water_flowing_content_id = minetest.get_content_id("default:water_flowing")

	river_water_source_content_id = minetest.get_content_id("default:river_water_source")
	river_water_flowing_content_id = minetest.get_content_id("default:river_water_flowing")

	lava_source_content_id = minetest.get_content_id("default:lava_source")
	lava_flowing_content_id = minetest.get_content_id("default:lava_flowing")

	--if minetest.get_modpath("dynamic_liquid") then
	--	block_water_source_content_id = minetest.get_content_id("dynamic_liquid:block_water_source")
	--	block_river_water_source_content_id = minetest.get_content_id("dynamic_liquid:block_river_water_source")
	--	block_lava_source_content_id = minetest.get_content_id("dynamic_liquid:block_lava_source")
	--end

	-- Fill a list with data for content IDs, after all nodes are registered
	for name, def in pairs(minetest.registered_nodes) do
		content_id_data[minetest.get_content_id(name)] = {
			name = name,
			walkable = def.walkable,
			buildable_to = def.buildable_to,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
		}
	end
end)



landscape_shaping.area_filter = {}

landscape_shaping.area_filter.sphere = function( fx_radius , x , y , z )
	return vector.length( vector.new( x, y, z ) ) <= fx_radius
end

landscape_shaping.area_filter.sphere_with_random_edge = function( fx_radius , x , y , z )
	local r = vector.length( vector.new( x, y, z ) )
	return r <= fx_radius and r <= fx_radius * ( rng:next(80, 100) / 100 )
end

landscape_shaping.area_filter.hemisphere = function( fx_radius , x , y , z )
	return y > 0 and vector.length( vector.new( x, y, z ) ) <= fx_radius
end

landscape_shaping.area_filter.hemisphere_or_equal = function( fx_radius , x , y , z )
	return y >= 0 and vector.length( vector.new( x, y, z ) ) <= fx_radius
end

landscape_shaping.area_filter.down_hemisphere = function( fx_radius , x , y , z )
	return y < 0 and vector.length( vector.new( x, y, z ) ) <= fx_radius
end

landscape_shaping.area_filter.down_hemisphere_or_equal = function( fx_radius , x , y , z )
	return y <= 0 and vector.length( vector.new( x, y, z ) ) <= fx_radius
end

landscape_shaping.area_filter.flat_square = function( fx_radius , x , y , z )
	return y == 0
end



landscape_shaping.content_filter = {}

landscape_shaping.content_filter.any = function( content_id )
	return true
end

landscape_shaping.content_filter.air = function( content_id )
	return content_id == air_content_id
end

landscape_shaping.content_filter.non_air = function( content_id )
	return content_id ~= air_content_id
end

landscape_shaping.content_filter.solid = function( content_id )
	return content_id_data[content_id] and content_id_data[content_id].walkable
end

landscape_shaping.content_filter.non_solid = function( content_id )
	return content_id_data[content_id] and not content_id_data[content_id].walkable
end

landscape_shaping.content_filter.solid_block = function( content_id )
	return content_id_data[content_id] and content_id_data[content_id].walkable and not content_id_data[content_id].buildable_to
end

landscape_shaping.content_filter.non_solid_block = function( content_id )
	return content_id_data[content_id] and not content_id_data[content_id].walkable and content_id_data[content_id].buildable_to
end

landscape_shaping.content_filter.buildable_to = function( content_id )
	return content_id_data[content_id] and content_id_data[content_id].buildable_to
end

landscape_shaping.content_filter.non_buildable_to = function( content_id )
	return content_id_data[content_id] and not content_id_data[content_id].buildable_to
end

landscape_shaping.content_filter.water = function( content_id )
	return (
		content_id == block_water_source_content_id
		or content_id == water_source_content_id
		or content_id == water_flowing_content_id
		or content_id == block_river_water_source_content_id
		or content_id == river_water_source_content_id
		or content_id == river_water_flowing_content_id
	)
end

landscape_shaping.content_filter.non_water = function( content_id )
	return not (
		content_id == block_water_source_content_id
		or content_id == water_source_content_id
		or content_id == water_flowing_content_id
		or content_id == block_river_water_source_content_id
		or content_id == river_water_source_content_id
		or content_id == river_water_flowing_content_id
	)
end

landscape_shaping.content_filter.lava = function( content_id )
	return (
		content_id == block_lava_source_content_id
		or content_id == lava_source_content_id
		or content_id == lava_flowing_content_id
	)
end

landscape_shaping.content_filter.non_lava = function( content_id )
	return not (
		content_id == block_lava_source_content_id
		or content_id == lava_source_content_id
		or content_id == lava_flowing_content_id
	)
end



landscape_shaping.heightmap_filter = {}



-- Average of 8 closest neighbors
landscape_shaping.heightmap_filter.avg_8 = function( heightmap , size , pass_number )
	local new_heightmap = {}
	local border_size = pass_number

	-- Now compute the height map smoothing
	for z = -size, size do
		new_heightmap[ z ] = {}
		for x = -size, size do
			if z < -size + border_size or z > size - border_size or x < -size + border_size or x > size - border_size then
				-- We are on the border, just copy
				new_heightmap[ z ][ x ] = heightmap[ z ][ x ]
			else
				-- Smooth with neighbor
				new_heightmap[ z ][ x ] = (
					heightmap[ z ][ x ]
					+ heightmap[ z + 1 ][ x ]
					+ heightmap[ z - 1 ][ x ]
					+ heightmap[ z ][ x + 1 ]
					+ heightmap[ z ][ x - 1 ]
					+ heightmap[ z + 1 ][ x + 1 ]
					+ heightmap[ z + 1 ][ x - 1 ]
					+ heightmap[ z - 1 ][ x + 1 ] 
					+ heightmap[ z - 1 ][ x - 1 ] 
				) / 9
			end
		end
	end
	
	return new_heightmap
end



-- Average of 20 closest neighbors
landscape_shaping.heightmap_filter.avg_20 = function( heightmap , size , pass_number )
	local new_heightmap = {}
	local border_size = 1 + pass_number

	-- Now compute the height map smoothing
	for z = -size, size do
		new_heightmap[ z ] = {}
		for x = -size, size do
			if z < -size + border_size or z > size - border_size or x < -size + border_size or x > size - border_size then
				-- We are on the border, just copy
				new_heightmap[ z ][ x ] = heightmap[ z ][ x ]
			else
				-- Smooth with neighbor
				new_heightmap[ z ][ x ] = (
					heightmap[ z ][ x ]
					+ heightmap[ z + 1 ][ x ]
					+ heightmap[ z - 1 ][ x ]
					+ heightmap[ z ][ x + 1 ]
					+ heightmap[ z ][ x - 1 ]
					+ heightmap[ z + 1 ][ x + 1 ]
					+ heightmap[ z + 1 ][ x - 1 ]
					+ heightmap[ z - 1 ][ x + 1 ] 
					+ heightmap[ z - 1 ][ x - 1 ] 

					+ heightmap[ z + 2 ][ x ]
					+ heightmap[ z - 2 ][ x ]
					+ heightmap[ z ][ x + 2 ]
					+ heightmap[ z ][ x - 2 ]
					+ heightmap[ z + 2 ][ x + 1 ]
					+ heightmap[ z + 1 ][ x + 2 ]
					+ heightmap[ z + 2 ][ x - 1 ]
					+ heightmap[ z + 1 ][ x - 2 ]
					+ heightmap[ z - 2 ][ x + 1 ] 
					+ heightmap[ z - 1 ][ x + 2 ] 
					+ heightmap[ z - 2 ][ x - 1 ] 
					+ heightmap[ z - 1 ][ x - 2 ] 
				) / 21
			end
		end
	end
	
	return new_heightmap
end



local function random_position(center, pos, radius)
	local def
	local reg_nodes = minetest.registered_nodes
	local i = 0
	repeat
		-- Give up and use the center if this takes too long
		if i > 4 then
			pos.x, pos.z = center.x, center.z
			break
		end
		pos.x = center.x + math.random(-radius, radius)
		pos.z = center.z + math.random(-radius, radius)
		def = reg_nodes[minetest.get_node(pos).name]
		i = i + 1
	until def and not def.walkable
end



local function add_drops(drops, node_drops)
	if not node_drops then return end

	for _, item in pairs(node_drops) do
		local item_stack = ItemStack(item)
		local item_name = item_stack:get_name()

		if landscape_shaping.drop_chance[item_name] == nil or rng:next(0,100) < landscape_shaping.drop_chance[item_name] then
			local drop = drops[item_name]
			if drop == nil then
				drops[item_name] = item_stack
			else
				drop:set_count(drop:get_count() + item_stack:get_count())
			end
		end
	end
end



local function eject_drops(drops, pos, radius)
	local drop_pos = vector.new(pos)

	for _, item in pairs(drops) do
		local count = math.min(item:get_count(), item:get_stack_max())
		while count > 0 do
			local take = math.max(1,math.min(radius * radius,
					count,
					item:get_stack_max()))
			random_position(pos, drop_pos, radius)
			local dropitem = ItemStack(item)
			dropitem:set_count(take)
			local obj = minetest.add_item(drop_pos, dropitem)
			if obj then
				obj:get_luaentity().collect = true
				obj:set_acceleration({x = 0, y = -10, z = 0})
				obj:set_velocity({x = math.random(-3, 3),
						y = math.random(0, 10),
						z = math.random(-3, 3)})
			end
			count = count - take
		end
	end
end



landscape_shaping.blow = function(player, pos, radius, params)
	-- parameter management
	params = params or {}
	local area_filter = params.area_filter or landscape_shaping.area_filter.sphere
	local content_filter = params.content_filter or landscape_shaping.content_filter.non_air
	local replacement_node_name = params.replacement_node or params.replacement_node_name or "air"
	local use_node_blast = params.use_blast or params.use_node_blast or false
	local can_drop = params.can_drop or false
	local ignore_protection = params.ignore_protection or false

	pos = vector.round(pos)
	
	local count = 1
	local voxel_manip = VoxelManip()

	local min_pos = vector.subtract(pos, radius)
	local max_pos = vector.add(pos, radius)
	min_pos, max_pos = voxel_manip:read_from_map(min_pos, max_pos)

	local voxel_area = VoxelArea:new({MinEdge = min_pos, MaxEdge = max_pos})
	local voxel_data = voxel_manip:get_data()

	local drops = {}
	local on_blast_queue = {}
	local on_construct_queue = {}
	local current_pos = {x = 0, y = 0, z = 0}
	local replacement_content_id = minetest.get_content_id(replacement_node_name)
	local current_content_id , current_def

	for y = -radius, radius do
		current_pos.y = pos.y + y

		for z = -radius, radius do
			current_pos.z = pos.z + z
			local voxel_index = voxel_area:index(pos.x + (-radius), current_pos.y, current_pos.z)
			
			for x = -radius, radius do
				current_pos.x = pos.x + x
				current_content_id = voxel_data[voxel_index]
				current_def = content_id_data[ current_content_id ]
				
				if
					area_filter( radius , x , y , z )
					and content_filter( current_content_id )
					and ( ignore_protection or not minetest.is_protected( current_pos, player) )
				then
					if current_def then
						if use_node_blast and current_def.on_blast then
							-- use blast on this node
							on_blast_queue[#on_blast_queue + 1] = {
								pos = vector.new(current_pos),
								on_blast = current_def.on_blast
							}
						elseif can_drop then
							-- ... or try to drop item
							local node_drops = minetest.get_node_drops(current_def.name, "")
							add_drops( drops , node_drops )
						end
					end

					voxel_data[voxel_index] = replacement_content_id
				end
				
				voxel_index = voxel_index + 1
			end
		end
	end

	voxel_manip:set_data(voxel_data)
	voxel_manip:write_to_map()
	voxel_manip:update_map()
	voxel_manip:update_liquids()

	-- call check_single_for_falling for everything within 1.5x blast radius
	for y = -radius * 1.5, radius * 1.5 do
		for z = -radius * 1.5, radius * 1.5 do
			for x = -radius * 1.5, radius * 1.5 do
				local rad = {x = x, y = y, z = z}
				local s = vector.add(pos, rad)
				local r = vector.length(rad)
				if r / radius < 1.4 then
					minetest.check_single_for_falling(s)
				end
			end
		end
	end

	for _, queued_data in pairs(on_blast_queue) do
		local dist = math.max(1, vector.distance(queued_data.pos, pos))
		local intensity = (radius * radius) / (dist * dist)
		local node_drops = queued_data.on_blast(queued_data.pos, intensity, pos)

		if can_drop then
			add_drops( drops , node_drops )
		end
	end
	
	if can_drop then
		eject_drops(drops, pos, radius)
	end

	--for _, queued_data in pairs(on_construct_queue) do
	--	queued_data.fn(queued_data.pos)
	--end

	minetest.log("action", "Landscape blowed by " .. ( player:get_player_name() or "(unknown)" ) .. " at " .. minetest.pos_to_string(pos) .. " with radius " .. radius)

	return drops, radius
end



landscape_shaping.fall = function(player, pos, radius, params)
	-- parameter management
	params = params or {}
	local area_filter = params.area_filter or landscape_shaping.area_filter.sphere
	local content_filter = params.content_filter or landscape_shaping.content_filter.non_air
	local fall_radius = params.fall_radius or math.floor( 32 + 1.5 * radius )
	local ignore_protection = params.ignore_protection or false

	pos = vector.round(pos)
	
	local count = 1
	local voxel_manip = VoxelManip()

	local min_pos = vector.subtract(pos, radius)
	min_pos.y = pos.y - fall_radius
	local max_pos = vector.add(pos, radius)
	min_pos, max_pos = voxel_manip:read_from_map(min_pos, max_pos)

	local voxel_area = VoxelArea:new({MinEdge = min_pos, MaxEdge = max_pos})
	local voxel_data = voxel_manip:get_data()

	local current_pos = {x = 0, y = 0, z = 0}
	local current_content_id , current_def , current_fall_content_id

	for y = -radius, radius do
		current_pos.y = pos.y + y

		for z = -radius, radius do
			current_pos.z = pos.z + z
			local voxel_index = voxel_area:index(pos.x + (-radius), current_pos.y, current_pos.z)
			
			for x = -radius, radius do
				current_pos.x = pos.x + x
				current_content_id = voxel_data[voxel_index]
				current_def = content_id_data[ current_content_id ]
				
				if
					area_filter( radius , x , y , z )
					and content_filter( current_content_id )
					and ( ignore_protection or not minetest.is_protected( current_pos, player) )
				then
					local current_fall_y_pos , fall_voxel_index , last_fall_voxel_index
					
					for fall_y = y - 1, - fall_radius, -1 do
						current_fall_y_pos = pos.y + fall_y
						fall_voxel_index = voxel_area:index(current_pos.x, current_fall_y_pos, current_pos.z)
						current_fall_content_id = voxel_data[fall_voxel_index]
						
						if landscape_shaping.content_filter.non_solid_block( current_fall_content_id ) then
							last_fall_voxel_index = fall_voxel_index
						end
					end
					
					if last_fall_voxel_index ~= nil then
						voxel_data[voxel_index] = air_content_id
						voxel_data[last_fall_voxel_index] = current_content_id
					end
				end
				
				voxel_index = voxel_index + 1
			end
		end
	end

	voxel_manip:set_data(voxel_data)
	voxel_manip:write_to_map()
	voxel_manip:update_map()
	voxel_manip:update_liquids()

	-- call check_single_for_falling for everything within 1.5x blast radius
	for y = radius , radius * 1.5 do
		for z = -radius , radius do
			for x = -radius , radius do
				local rad = {x = x, y = y, z = z}
				local s = vector.add(pos, rad)
				minetest.check_single_for_falling(s)
			end
		end
	end

	minetest.log("action", "Landscape falling done by " .. ( player:get_player_name() or "(unknown)" ) .. " at " .. minetest.pos_to_string(pos) .. " with radius " .. radius)

	return radius
end



landscape_shaping.cover = function(player, pos, radius, params)
	-- parameter management
	params = params or {}
	local area_filter = params.area_filter or landscape_shaping.area_filter.sphere
	local content_filter = params.content_filter or landscape_shaping.content_filter.buildable_to
	local replacement_node_name = params.replacement_node or params.replacement_node_name or "default:dirt"
	local ignore_protection = params.ignore_protection or false

	pos = vector.round(pos)
	
	local count = 1
	local voxel_manip = VoxelManip()

	local min_pos = vector.subtract(pos, radius)
	min_pos.y = min_pos.y - 1
	local max_pos = vector.add(pos, radius)
	min_pos, max_pos = voxel_manip:read_from_map(min_pos, max_pos)

	local voxel_area = VoxelArea:new({MinEdge = min_pos, MaxEdge = max_pos})
	local voxel_data = voxel_manip:get_data()

	local current_pos = {x = 0, y = 0, z = 0}
	local replacement_content_id = minetest.get_content_id(replacement_node_name)
	local current_content_id , current_def , current_below_content_id

	-- We start from top to bottom for obvious reason, if not, we would cover over previously covered nodes
	for y = radius, -radius, -1 do
		current_pos.y = pos.y + y

		for z = -radius, radius do
			current_pos.z = pos.z + z
			local voxel_index = voxel_area:index(pos.x + (-radius), current_pos.y, current_pos.z)
			local below_voxel_index
			
			for x = -radius, radius do
				current_pos.x = pos.x + x
				current_content_id = voxel_data[voxel_index]
				current_def = content_id_data[ current_content_id ]
				
				if
					area_filter( radius , x , y , z )
					and content_filter( current_content_id )
					and ( ignore_protection or not minetest.is_protected( current_pos, player) )
				then
					
					below_voxel_index = voxel_area:index(current_pos.x, current_pos.y - 1, current_pos.z)
					current_below_content_id = voxel_data[below_voxel_index]
					
					if landscape_shaping.content_filter.solid_block( current_below_content_id ) then
						voxel_data[voxel_index] = replacement_content_id
					end
				end
				
				voxel_index = voxel_index + 1
			end
		end
	end

	voxel_manip:set_data(voxel_data)
	voxel_manip:write_to_map()
	voxel_manip:update_map()
	voxel_manip:update_liquids()

	minetest.log("action", "Landscape cover done by " .. ( player:get_player_name() or "(unknown)" ) .. " at " .. minetest.pos_to_string(pos) .. " with radius " .. radius)

	return radius
end



landscape_shaping.heightmap = function(player, pos, radius, params)
	-- parameter management
	params = params or {}
	--local area_filter = params.area_filter or landscape_shaping.area_filter.sphere
	local content_filter = params.content_filter or landscape_shaping.content_filter.solid_block
	local heightmap_filter = params.heightmap_filter or landscape_shaping.heightmap_filter.avg_8
	local replacement_node_name = params.replacement_node or params.replacement_node_name or "air"
	local pass = params.pass or 1
	local ignore_protection = params.ignore_protection or false

	pos = vector.round(pos)
	local max_y_radius = math.floor( 16 + 1.5 * radius )
	local min_y_radius = math.floor( 32 + 1.5 * radius )	-- always try to check/smooth more in depth
	
	local count = 1
	local voxel_manip = VoxelManip()

	local min_pos = vector.subtract(pos, radius + 1)
	local max_pos = vector.add(pos, radius + 1)
	min_pos.y = pos.y - min_y_radius
	max_pos.y = pos.y + max_y_radius
	min_pos, max_pos = voxel_manip:read_from_map(min_pos, max_pos)

	local voxel_area = VoxelArea:new({MinEdge = min_pos, MaxEdge = max_pos})
	local voxel_data = voxel_manip:get_data()

	local current_pos = {x = 0, y = 0, z = 0}
	local replacement_content_id = minetest.get_content_id(replacement_node_name)
	local current_content_id , current_def , voxel_index
	local heightmap = {}

	-- Height map building: we start from top to bottom and stop on the first solid block
	for z = -radius - 1, radius + 1 do
		current_pos.z = pos.z + z
		heightmap[ z ] = {}

		for x = -radius - 1, radius + 1 do
			current_pos.x = pos.x + x
			heightmap[ z ][ x ] = - min_y_radius - 1

			for y = max_y_radius, -min_y_radius, -1 do
				current_pos.y = pos.y + y
				voxel_index = voxel_area:index( current_pos.x, current_pos.y, current_pos.z )
				current_content_id = voxel_data[voxel_index]
				current_def = content_id_data[ current_content_id ]
				
				if content_filter( current_content_id ) then
					-- found it, mark height map and break!
					heightmap[ z ][ x ] = y
					break
				end
			end
		end
	end


	local new_heightmap = heightmap
	
	-- Now perform the height map smooth passes
	for current_pass = 1, pass do
		new_heightmap = heightmap_filter( new_heightmap , radius + 1, current_pass )
	end
	

	-- Apply the new height map
	for z = -radius, radius do
		current_pos.z = pos.z + z

		for x = -radius, radius do
			local current_y = heightmap[ z ][ x ]
			
			-- We don't change things with height map level at min+1 or max-1 because they are unsafe
			if current_y > -min_y_radius + 1 and current_y < max_y_radius - 1 then

				-- The new height map is filled with floating point numbers
				local new_y = math.floor( 0.5 + new_heightmap[ z ][ x ] )

				local new_voxel_index
				local above_current_voxel_index , above_current_content_id , above_new_voxel_index
				local below_current_voxel_index , below_current_content_id , below_new_voxel_index
				local filler_voxel_index
				
				if current_y ~= new_y then
					-- We always preserve the 2 voxels above and 2 voxels below in the raise/lower process, to have produce a better effect.
					-- Above voxels can be grass, snow slab or water
					voxel_index = voxel_area:index( pos.x + x, pos.y + current_y, pos.z + z)
					current_content_id = voxel_data[voxel_index]
					above_current_voxel_index = voxel_area:index( pos.x + x, pos.y + current_y + 1, pos.z + z)
					above_current_content_id = voxel_data[above_current_voxel_index]
					above2_current_voxel_index = voxel_area:index( pos.x + x, pos.y + current_y + 2, pos.z + z)
					above2_current_content_id = voxel_data[above2_current_voxel_index]
					below_current_voxel_index = voxel_area:index( pos.x + x, pos.y + current_y - 1, pos.z + z)
					below_current_content_id = voxel_data[below_current_voxel_index]
					below2_current_voxel_index = voxel_area:index( pos.x + x, pos.y + current_y - 2, pos.z + z)
					below2_current_content_id = voxel_data[below2_current_voxel_index]

					new_voxel_index = voxel_area:index( pos.x + x, pos.y + new_y, pos.z + z)
					above_new_voxel_index = voxel_area:index( pos.x + x, pos.y + new_y + 1, pos.z + z)
					above2_new_voxel_index = voxel_area:index( pos.x + x, pos.y + new_y + 2, pos.z + z)
					below_new_voxel_index = voxel_area:index( pos.x + x, pos.y + new_y - 1, pos.z + z)
					below2_new_voxel_index = voxel_area:index( pos.x + x, pos.y + new_y - 2, pos.z + z)
					
					if current_y > new_y then
						-- So we lower the current voxel

						-- The order matters
						voxel_data[below2_new_voxel_index] = below2_current_content_id
						voxel_data[below_new_voxel_index] = below_current_content_id
						voxel_data[new_voxel_index] = current_content_id
						voxel_data[above_new_voxel_index] = above_current_content_id
						voxel_data[above2_new_voxel_index] = above2_current_content_id

						-- Fill voxels above the new height using air/replacement
						for y = new_y + 3, current_y + 1 do
							filler_voxel_index = voxel_area:index( pos.x + x, pos.y + y, pos.z + z)
							voxel_data[filler_voxel_index] = replacement_content_id
						end
					elseif current_y < new_y then
						-- So we raise the current voxel

						-- The order matters
						voxel_data[above2_new_voxel_index] = above2_current_content_id
						voxel_data[above_new_voxel_index] = above_current_content_id
						voxel_data[new_voxel_index] = current_content_id
						voxel_data[below_new_voxel_index] = below_current_content_id
						voxel_data[below2_new_voxel_index] = below2_current_content_id

						-- Fill voxels below the new height, using what was below the current node
						for y = new_y - 3, current_y, -1 do
							filler_voxel_index = voxel_area:index( pos.x + x, pos.y + y, pos.z + z)
							voxel_data[filler_voxel_index] = below2_current_content_id
						end
					end
				end
			end
		end
	end

	voxel_manip:set_data(voxel_data)
	voxel_manip:write_to_map()
	voxel_manip:update_map()
	voxel_manip:update_liquids()

	minetest.log("action", "Landscape smoothing done by " .. ( player:get_player_name() or "(unknown)" ) .. " at " .. minetest.pos_to_string(pos) .. " with radius " .. radius)

	return radius
end

