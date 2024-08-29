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

function floodFill(targetBlockNames)

    lib_move.setHome()

    while true do
        if lib_move.distToHome() >= 64 then
            print("out of range, terminating program")
            lib_move.goHome()
            return
        end

        --move in first direction that has a block on target list
        local success, blockInfo
        local moveMade = false
        --up
        if not moveMade then
            success, blockInfo = turtle.inspectUp()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                if not lib_move.charMove("U", true, true) then
                    print("move failed")
                    lib_move.goHome()
                    return false
                end
                moveMade = true
            end
        end

        --down
        if not moveMade then
            success, blockInfo = turtle.inspectDown()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                if not lib_move.charMove("D", true, true) then
                    print("move failed")
                    lib_move.goHome()
                    return false
                end
                moveMade = true
            end
        end

        --forward
        if not moveMade then
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                if not lib_move.charMove("F", true, true) then
                    print("move failed")
                    lib_move.goHome()
                    return false
                end
                moveMade = true
            end
        end

        --left 
        if not moveMade then
            lib_move.macroMove("L", false, true)
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                lib_move.appendMoveMem("L")
                if not lib_move.macroMove("F", true, true) then
                    print("move failed")
                    lib_move.goHome()
                    return false
                end
                moveMade = true
            else
                lib_move.macroMove("R", false, true)
            end
        end

        --back
        if not moveMade then
            lib_move.macroMove("LL", false, true)
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                lib_move.appendMoveMem("LL")
                if not lib_move.macroMove("F", true, true) then
                    print("move failed")
                    lib_move.goHome()
                    return false
                end
                moveMade = true
            else
                lib_move.macroMove("RR", false, true)
            end
        end

        --right
        if not moveMade then
            lib_move.macroMove("R", false, true)
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                lib_move.appendMoveMem("R")
                if not lib_move.macroMove("F", true, true) then
                    print("move failed")
                    lib_move.goHome()
                    return false
                end
                moveMade = true
            else
                lib_move.macroMove("L", false, true)
            end
        end

        --if none step back one move in memory and look again
        if not moveMade then
            local turnMoveFlag = false
            while true do
                local lastMove = lib_move.popBackMoveMem()
                if lastMove == "R" or lastMove == "L" then
                    turnMoveFlag = true
                else
                    turnMoveFlag = false
                end
                if lastMove == nil then
                    return true
                end
                lib_move.charMove(lib_move.revMoveChar(lastMove),false,true)
                if not turnMoveFlag then
                    break
                end
            end
        end
    end
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
        print("flood fill demo")
        local targetBlocks = {args[2]}
        floodFill(targetBlocks)
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
    end
    
else
    print("Please provide valid arguments:")
    print("1: horizontal move loop test")
    print("2: vertical move loop test")
    print("3: spiral sweep test")
    print("4: print block below")
    print("5: flood fill clear")
    print("6: diving bell")
    print("7: turtle up")
end