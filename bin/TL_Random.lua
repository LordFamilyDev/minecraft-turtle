local lib_mining = require("/lib/lib_mining")
local lib_itemTypes = require("/lib/item_types")
local lib_move = require("/lib/move")
local lib_farming = require("/lib/farming")

function toFile(string)
    local file = fs.open("debugFile", "w")
    file.writeLine(string)
    file.close()
end

function inspectDownToPrint()
    local success, data = turtle.inspectDown()

    if success then
        for key, value in pairs(data) do
            print(key .. ": " .. tostring(value))
        end

        -- If `data.state` exists and is a table, you can print its contents as well
        if data.state then
            print("State:")
            for key, value in pairs(data.state) do
                print("  " .. key .. ": " .. tostring(value))
            end
        end
    else
        print("No block detected.")
    end
end

function isTargetBlock(blockInfo, targetBlockNames)
    --toFile(textutils.serialize(blockInfo))
    if lib_itemTypes.isItemInList(blockInfo.name, targetBlockNames) then
        if blockInfo.name == "minecraft:lava" and blockInfo.state.level > 0 then
            return false
        else
            return true
        end
    end
    return false
end

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
    elseif arg1 == 3 then
        turtle.up()
        lib_farming.sweepUp(4)
        turtle.down()
    elseif arg1 == 4 then
        lib_move.goForward(true)
        inspectDownToPrint()
    elseif arg1 == 5 then
        print("vein miner")
        lib_move.setHome()
        lib_move.setTether(64,true)
        local failedMoveFlag = false

        local targetBlocks = {}
        local dir = args[2]
        if dir == "u" then
            while not turtle.inspectUp() do
                failedMoveFlag = lib_move.goUp(true)
            end
        elseif dir == "f" then
            while not turtle.inspect() do
                failedMoveFlag = lib_move.goForward(true)
            end
        else

        end
        for i = 3, #args do
            table.insert(targetBlocks, args[i])
        end

        if not failedMoveFlag then
            failedMoveFlag = lib_move.floodFill(targetBlocks, false)
        end

        if failedMoveFlag then
            lib_move.goHome()
        end
    elseif arg1 == 6 then
        turtle.up()
        turtle.up()
        turtle.placeUp()
        for i = 1, 4 do
            turtle.place()
            turtle.turnRight()
        end
        turtle.down()
        turtle.placeUp()
        turtle.digUp()
        turtle.forward()
    elseif arg1 == 7 then
        local dist = tonumber(args[2])
        if dist == nil then
            dist = 1
        end
        for i = 0, dist do
            turtle.digUp()
            turtle.up()
        end
    elseif arg1 == 8 then
        local blocks = {"minecraft:lava","minecraft:obsidian"}

        function bucketUp()
            turtle.placeUp()
            sleep(0.3)
            turtle.placeUp()
        end

        lib_move.floodFill(blocks,true, bucketUp)
    end
    
else
    print("Please provide valid arguments:")
    print("1: horizontal move loop test")
    print("2: vertical move loop test")
    print("3: spiral sweep test")
    print("4: print block below")
    print("5: vein miner")
    print("6: diving bell")
    print("7: turtle up")
    print("8: obsidian miner")
end