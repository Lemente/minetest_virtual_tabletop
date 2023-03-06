-- Global landscape_shaping namespace
landscape_shaping = {}
landscape_shaping.path = minetest.get_modpath( minetest.get_current_modname() )

-- Load files
dofile( landscape_shaping.path .. "/reshape.lua" )
dofile( landscape_shaping.path .. "/wands.lua" )


