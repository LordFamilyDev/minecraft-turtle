local m = require("/lib/move")
local item = require("/lib/item_types")
local lib_debug = require("/lib/lib_debug")

-- Parse command-line arguments
local args = {...}
local SHAFT_LENGTH = 32
local TUNNEL_WIDTH = 3
local TORCH_INTERVAL = 8

local wall_material = 
{
    "cobble",
    "polished"
}

for i = 1, #args do
    if args[i] == "-v" then
        lib_debug.set_verbose(true)
    elseif args[i] == "-l" and args[i+1] then
        SHAFT_LENGTH = tonumber(args[i+1])
    end
end


local function ui()
end


local function checkMats()
end


local function main()
end


main()