local modname = minetest.get_current_modname()
local basename
local S = minetest.get_translator(modname)
local candle_recipes = 0
local creative_server = minetest.is_creative_enabled("")

local leader_color = "orange" -- Arbitrary decision
local candle_count = minetest.settings:get("candles_3d-candles_per_node")
candle_count = tonumber(candle_count) or 5
candle_count = math.max(candle_count, 1)
candle_count = math.min(candle_count, 5)
candle_count = math.floor(candle_count)
local deprecated = minetest.settings:get_bool("candles_3d-deprecated_nodes", false)

local mcl
if minetest.get_modpath("mcl_fire") then
	basename = "mcl_candles"
	mcl = true
else
	basename = modname
end

local supported_colors = {}

if mcl then
	supported_colors["white"] = S("White")
	supported_colors["lightgrey"] = S("Light Grey")
	supported_colors["grey"] = S("Grey")
	supported_colors["darkgrey"] = S("Dark Grey")
	supported_colors["black"] = S("Black")
	supported_colors["red"] = S("Red")
	supported_colors["orange"] = S("Orange")
	supported_colors["yellow"] = S("Yellow")
	supported_colors["lime"] = S("Lime")
	supported_colors["green"] = S("Green")
	supported_colors["aqua"] = S("Aqua")
	supported_colors["cyan"] = S("Cyan")
	--supported_colors["sky_blue"] = S("sky_blue")
	supported_colors["blue"] = S("Blue")
	supported_colors["violet"] = S("Violet")
	supported_colors["magenta"] = S("Magenta")
	--supported_colors["red_violet"] = S("red_violet")
elseif minetest.get_modpath("dye") then
	for _, color in ipairs(dye.dyes) do
		color[1] = color[1]:gsub("_","")
		supported_colors[color[1]] = S(color[2])
	end
end

local is_candle = function(stack)
	return stack:get_name():sub(1,#basename+1) == basename .. ":"
end

local is_supported_color = function(strings)
	if not strings or ( strings[1] ~= "dye"
		and strings[1] ~= "mcl_dye" ) then
		return false
	end
	for color,_ in pairs(supported_colors) do
		if color == strings[2] then
			return true
		end
	end
	return false
end

local ignite = function(pos, igniter)
	local node = minetest.get_node(pos)
	minetest.swap_node(pos,
		{ param2 = node.param2,
		name = node.name:gsub("unlit_", "")
	})
end

local mcl_candle_ignite = function(player, pointed_thing)
	ignite(pointed_thing.under, player)
	return true
end

local candle_same_color = function(nodename, stackname)
	local nodecolor, stackcolor
	stackcolor = stackname:gsub(basename .. ":unlit_", "")
	stackcolor = stackcolor:gsub("_.*","")
	nodecolor = nodename:gsub(basename .. ":", "")
	nodecolor = nodecolor:gsub("unlit_", "")
	nodecolor = nodecolor:gsub("_.*","")
	return nodecolor == stackcolor
end

local register_candle = function(color, count)
	-- Initialize candle definition
	local def = {
		drawtype = "mesh",
		paramtype = "light",
		tiles = {{
			name = "candles_3d.png^(candles_3d-wax.png^[colorize:" .. color .. ":127)",
			animation = {
				type = "vertical_frames",
				aspect_w = 48,
				aspect_h = 16,
				length = 3.0,
			},
		}},
		mesh = "candles_3d_" .. count .. ".obj",
		walkable = false,
		floodable = true,
		groups = {dig_immediate=3, attached_node=1},
		paramtype2 = "facedir",
		light_source = count + 3,
		use_texture_alpha = "blend",
	}
	if mcl then
		def.groups.dig_immediate = 2
	end
	local action = function(pos, node, clicker, itemstack, pointed_thing)
		local pn = clicker:get_player_name()
		if minetest.is_protected(pos, pn) then
			return
		end

		if mcl then
			pointed_thing = itemstack
			itemstack = clicker:get_wielded_item()
		end

		local unlit = ""
		if node.name:find("unlit_") then
			unlit = "unlit_"
		end

		-- When player holds a candle_3d increase candle counts in node
		if is_candle(itemstack) then
			if count < candle_count and
				(not mcl or candle_same_color(node.name, itemstack:get_name())) then
				minetest.swap_node(pos, { param2 = node.param2,
					name = basename .. ":" .. unlit .. color .. "_" .. count + 1 })
				if creative_server or
					minetest.check_player_privs(pn, "creative") then
					return
				end
				itemstack:take_item()
				if mcl then
					clicker:set_wielded_item(itemstack)
				else
					return itemstack
				end
			end
			return
		end

		-- When player holds a dye change the color of the node
		local mi_split = itemstack:get_name():split(":")
		if mi_split then
			mi_split[2] = mi_split[2]:gsub("dark_","dark")
		end
		if is_supported_color(mi_split) and color ~= mi_split[2]
			and ( not mcl or count == 1 ) then
			minetest.swap_node(pos, { param2 = node.param2,
				name = basename .. ":" .. unlit ..  mi_split[2] .. "_" .. count })
			if creative_server or
				minetest.check_player_privs(pn, "creative") then
				return
			end
			itemstack:take_item()
			if mcl then
				clicker:set_wielded_item(itemstack)
			else
				return itemstack
			end
		end

		-- Light up candles with torches when not mineclone
		if not mcl and unlit ~= "" and itemstack:get_name() == "default:torch" then
			minetest.swap_node(pos, { param2 = node.param2,
				name = basename .. ":" .. color .. "_" .. count })
		end
	end

	if mcl then
		def.on_punch = action
	else
		def.on_rightclick = action
	end

	if mcl then
		def.drop = basename .. ":unlit_" .. color .. "_1 " .. count
	else
		def.drop = basename .. ":unlit_" .. leader_color .. "_1 " .. count
	end

	if count > 1 then
		-- Take candles from node one by one
		def.on_dig = function(pos, node, digger)
			local pn = digger:get_player_name()
			if minetest.is_protected(pos, pn) then
				return
			end
			local name = basename .. ":"
			if node.name:find("unlit_") then
				name = name .. "unlit_"
			end
			name = name .. color .. "_" .. count - 1

			minetest.swap_node(pos, { param2 = node.param2, name = name})
			if creative_server or
				minetest.check_player_privs(pn, "creative") then
				return
			end
			local stack
			if mcl then
				stack = minetest.get_node_drops(node)[1]:split(" ")[1]
			else
				stack = ItemStack(basename .. ":unlit_" .. leader_color .. "_1")
				local inv = digger:get_inventory()
			end
			minetest.handle_node_drops(pos,{stack},digger)
		end
	end
	if not creative_server then
		def.on_flood = function(pos, oldnode, newnode)
			minetest.add_item(pos, ItemStack(def.drop))
			return false
		end
	end
	if minetest.get_modpath("screwdriver") then
		def.on_rotate = screwdriver.rotate_simple
	end

	-- Register illuminated candle node
	if mcl then
		minetest.register_node(":" .. basename .. ":" .. color .. "_" .. count, def)
	else
		local nn = basename .. ":" .. color .. "_" .. count
		minetest.register_node(nn, def)
		if deprecated then
			minetest.register_alias(basename .. ":candle_" .. color .. "_" .. count, nn)
		end
	end

	-- Adapt unlit candles definition
	def = table.copy(def)
	def.mesh = "candles_3d_unlit_" .. count .. ".obj"
	def.light_source = nil

	-- Register an entry in creative iventory
	if count == 1 and ( mcl or creative_server or color == leader_color ) then
		def.description = S("A placeable @1 candle", supported_colors[color])
		def.on_construct = function(pos)
			local param2 = math.random(4) - 1 -- Always on floor
			local node = minetest.get_node(pos)
			minetest.swap_node(pos, { name = node.name, param2 = param2 })
		end
	end

	-- Register unlit node
	if mcl then
		def._on_ignite = mcl_candle_ignite
		minetest.register_node(":" .. basename .. ":unlit_" .. color .. "_" .. count, def)
	else
		def.on_ignite = ignite
		local nn = basename .. ":unlit_" .. color .. "_" .. count
		minetest.register_node(nn, def)
	end
end

for color,_ in pairs(supported_colors) do
	for i = 1, candle_count do
		register_candle(color, i)
	end
end

if mcl then -- Recipe in mineclone
	minetest.register_craft({
		output = ":" .. basename .. ":" .. ":unlit_" .. leader_color .. "_1",
		recipe = {
			{"mcl_mobitems:string","", ""},
			{"mcl_honey:honeycomb",  "", "",},
			{"",  "", "",},
		}
	})
	for c1,_ in pairs(supported_colors) do
		for c2,_ in pairs(supported_colors) do
			if c1 ~= c2 then
				minetest.register_craft({
					type = "shapeless",
					output = ":" .. basename .. ":unlit_" .. c1 .. "_1",
					recipe = { basename .. ":unlit_" .. c2 .. "_1" ,
								"mcl_dye:" .. c1 },
				})
			end
		end
	end
	candle_recipes = candle_recipes + 1
elseif minetest.registered_items["farming:string"] then
	-- Recipe with bees + farming
	if minetest.get_modpath("bees") then
		minetest.register_craft({
			output = basename .. ":unlit_" .. leader_color .. "_1",
			recipe = {
				{'' , '', 'farming:string'},
				{'' ,  'bees:wax'    , '',},
				{'bees:wax' ,  ''    , '',},
			}
		})
		candle_recipes = candle_recipes + 1
	end
	-- Recipe with petz + farming
	if minetest.get_modpath("petz") then
		minetest.register_craft({
			type = "shapeless",
			output = basename .. ":unlit_" .. leader_color .. "_1",
			recipe = { "petz:beeswax_candle" }
		})
		candle_recipes = candle_recipes + 1
	end
	-- Recipe when only farming
	if candle_recipes == 0 then
		minetest.register_craft({
			output = basename .. ":unlit_blue_1",
			recipe = {
				{'','farming:string','',},
				{'','group:leaves'  ,'',},
				{'','group:leaves'  ,'',},
			}
		})
		candle_recipes = candle_recipes + 1
	end
end

if candle_recipes == 0 and not creative_server then
	minetest.log("warning", "[ Candles 3D ]: no recipe available: install bees and/or petz")
	minetest.log("warning", "[ Candles 3D ]: do it or use this mod via give privilege")
end
-- vim: ai:noet:ts=4:sw=4:fdm=indent:syntax=lua
