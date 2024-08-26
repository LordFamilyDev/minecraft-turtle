local lib_mining = require("/lib/lib_mining")
local lib_itemTypes = require("/lib/item_types")
local lib_move = require("/lib/move")

-- Capture arguments passed to the script
local args = {...}

local arg1 = tonumber(args[1])

-- Check if all arguments were provided and are valid integers
if arg1 then
    if arg1 == 1 then
        while true do
            lib_move.macroMove("FRFRFRFR",false,true)
        end
    elseif arg1 == 2 then
        while true do
            lib_move.macroMove("UFDRRFRR",false,true)
        end
    end
else
    print("Please provide valid arguments:")
    print("1: horizontal move loop test")
    print("2: vertical move loop test")
end