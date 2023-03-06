max_line_length = false
quiet = 1

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn", "insert_all"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "VoxelArea",

	-- deps
	"default",
	"farming",
	"minetest",
	"dye",
	"screwdriver",
}
