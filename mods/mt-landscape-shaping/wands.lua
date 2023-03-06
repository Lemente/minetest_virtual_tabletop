

landscape_shaping.player_copied_node_name = {}
landscape_shaping.player_reshape_radius = {}



local function transmute_wand_interact(player, pointed_thing, mode)
	if pointed_thing.type ~= "node" then return end

	-- A true player is required
	local player_name = player and player:get_player_name()
	if not player_name then return end

	local pos = pointed_thing.under
	local is_sneak = player and player:get_player_control().sneak or false

	-- Check for node protection
	if minetest.is_protected(pos, player_name) then
		minetest.chat_send_player(player_name, "You're not authorized to alter nodes in this area")
		minetest.record_protection_violation(pos, player_name)
		return
	end

	-- Retrieve group info and styles
	local node = minetest.get_node(pos)
	local node_name = node.name
	local style , group_name , group , new_style , new_node_name

	if mode == "copy" then
		-- Copy node
		landscape_shaping.player_copied_node_name[ player_name ] = node_name
		minetest.chat_send_player(player_name, "Transmute wand: node " .. node_name .. " copied")
		return
	elseif mode == "transmute" then
		-- Paste node
		--if not minetest.get_player_privs(player_name).creative then
		--	minetest.chat_send_player(player_name, "The transmute wand require the 'creative' privilege")
		--	return
		--end

		new_node_name = landscape_shaping.player_copied_node_name[ player_name ]

		if not new_node_name then
			minetest.chat_send_player(player_name, "No transmute node copied yet, left-click to copy a node")
			return
		end

		-- Already the correct node, exit now!
		if new_node_name == node_name then return end
	end
	
	
	-- Check if rotation could be preserved
	local nodedef = minetest.registered_nodes[node_name]
	local new_nodedef = minetest.registered_nodes[new_node_name]
	local rotation , new_rotation
	
	if nodedef and new_nodedef then
		if ( nodedef.paramtype2 == "facedir" or nodedef.paramtype2 == "colorfacedir" )
			and ( new_nodedef.paramtype2 == "facedir" or new_nodedef.paramtype2 == "colorfacedir" )
		then 
			rotation = node.param2 % 32		--rotation are on the last 5 digits
		end
	end

	-- Set the new node
	minetest.set_node(pos, {name= new_node_name})
	local new_node = minetest.get_node(pos)

	-- Copy rotation if needed!
	if rotation ~= nil then
		new_rotation = new_node.param2 % 32
		
		if new_rotation ~= rotation then
			new_node.param2 = new_node.param2 - new_rotation + rotation
			minetest.swap_node(pos, new_node)
		end
	end

	--minetest.sound_play("jonez_carve", {pos = pos, gain = 0.7, max_hear_distance = 5})
end



local function reshape_interact(player, pointed_thing, mode, is_right)
	-- A true player is required
	local player_name = player and player:get_player_name()
	if not player_name then return end

	local is_sneak = player:get_player_control().sneak or false
	local radius = landscape_shaping.player_reshape_radius[ player_name ] or 3
	
	if is_sneak then
		if is_right then
			radius = radius + 1 + math.floor( radius / 6 )
		elseif radius > 1 then
			radius = radius - 1 - math.floor( radius / 8 )
		end
		
		minetest.chat_send_player(player_name, "New radius for reshaping wands: " .. radius )
		landscape_shaping.player_reshape_radius[ player_name ] = radius
		return
	end

	if pointed_thing.type ~= "node" then return end
	local pos = pointed_thing.under
	local node = minetest.get_node(pos)
	local node_name = node.name
	
	if mode == "blow-sphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			use_blast = true
		})
	elseif mode == "blow-hemisphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.hemisphere,
			use_blast = true
		})
	elseif mode == "fill-down-hemisphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.down_hemisphere_or_equal,
			content_filter = landscape_shaping.content_filter.any,
			replacement_node = node_name
		})
	elseif mode == "fill-down-hemisphere-with-copy" then
		node_name = landscape_shaping.player_copied_node_name[ player_name ]

		if not node_name then
			minetest.chat_send_player(player_name, "No node copied yet")
			return
		end

		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.down_hemisphere_or_equal,
			content_filter = landscape_shaping.content_filter.any,
			replacement_node = node_name
		})
	elseif mode == "flat-square" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.flat_square,
			content_filter = landscape_shaping.content_filter.any,
			replacement_node = node_name
		})
	elseif mode == "flat-square-with-copy" then
		node_name = landscape_shaping.player_copied_node_name[ player_name ]

		if not node_name then
			minetest.chat_send_player(player_name, "No node copied yet")
			return
		end

		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.flat_square,
			content_filter = landscape_shaping.content_filter.any,
			replacement_node = node_name
		})
	elseif mode == "fall-sphere" then
		landscape_shaping.fall(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			content_filter = landscape_shaping.content_filter.non_air,
			fall_radius = 32 + 2 * radius
		})
	elseif mode == "cover-sphere" then
		landscape_shaping.cover(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			--content_filter = landscape_shaping.content_filter.non_solid_block,
			--replacement_node = node_name,
		})
	elseif mode == "cover-sphere-copy" then
		node_name = landscape_shaping.player_copied_node_name[ player_name ]

		if not node_name then
			minetest.chat_send_player(player_name, "No node copied yet")
			return
		end

		landscape_shaping.cover(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			--content_filter = landscape_shaping.content_filter.non_solid_block,
			replacement_node = node_name,
		})
	elseif mode == "smooth-sphere" then
		landscape_shaping.heightmap(player, pos, radius, {
			--replacement_node = node_name,
		})
	elseif mode == "smoother-sphere" then
		landscape_shaping.heightmap(player, pos, radius, {
			heightmap_filter = landscape_shaping.heightmap_filter.avg_20 ,
			pass = 2 + math.floor( radius / 5 )
		})
	elseif mode == "water-hemisphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.hemisphere,
			content_filter = landscape_shaping.content_filter.air,
			replacement_node = "default:water_source"
		})
	elseif mode == "evaporate-water-sphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			content_filter = landscape_shaping.content_filter.water
		})
	elseif mode == "lava-hemisphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			content_filter = landscape_shaping.content_filter.air,
			replacement_node = "default:lava_source"
		})
	elseif mode == "evaporate-lava-sphere" then
		landscape_shaping.blow(player, pos, radius, {
			area_filter = landscape_shaping.area_filter.sphere,
			content_filter = landscape_shaping.content_filter.lava
		})
	end

	minetest.chat_send_player(player_name, "Reshaped!")
end



minetest.register_craftitem("landscape_shaping:transmute_wand", {
	description = "Copy wand",
	inventory_image = "landscape_shaping_transmute_wand.png",
	wield_image = "landscape_shaping_transmute_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		transmute_wand_interact(player, pointed_thing,"copy")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		transmute_wand_interact(player, pointed_thing,"transmute",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:blow_wand", {
	description = "Blow wand",
	inventory_image = "landscape_shaping_blow_wand.png",
	wield_image = "landscape_shaping_blow_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"blow-sphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"blow-hemisphere",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:flat_hemisphere_wand", {
	description = "Flat hemisphere wand",
	inventory_image = "landscape_shaping_flat_hemisphere_wand.png",
	wield_image = "landscape_shaping_flat_hemisphere_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"fill-down-hemisphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"fill-down-hemisphere-with-copy",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:flat_square_wand", {
	description = "Flat square wand",
	inventory_image = "landscape_shaping_flat_square_wand.png",
	wield_image = "landscape_shaping_flat_square_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"flat-square")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"flat-square-with-copy",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:water_wand", {
	description = "Water wand",
	inventory_image = "landscape_shaping_water_wand.png",
	wield_image = "landscape_shaping_water_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"evaporate-water-sphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"water-hemisphere",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:lava_wand", {
	description = "Lava wand",
	inventory_image = "landscape_shaping_lava_wand.png",
	wield_image = "landscape_shaping_lava_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"evaporate-lava-sphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"lava-hemisphere",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:fall_wand", {
	description = "Fall wand",
	inventory_image = "landscape_shaping_fall_wand.png",
	wield_image = "landscape_shaping_fall_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"fall-sphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"fall-sphere",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:cover_wand", {
	description = "Cover wand",
	inventory_image = "landscape_shaping_cover_wand.png",
	wield_image = "landscape_shaping_cover_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"cover-sphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"cover-sphere-copy",true)
		return itemstack
	end,
})



minetest.register_craftitem("landscape_shaping:smooth_wand", {
	description = "Smooth wand",
	inventory_image = "landscape_shaping_smooth_wand.png",
	wield_image = "landscape_shaping_smooth_wand.png",
	on_use = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"smooth-sphere")
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		reshape_interact(player, pointed_thing,"smoother-sphere",true)
		return itemstack
	end,
})

