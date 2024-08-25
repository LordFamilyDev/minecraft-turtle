local lib_mining = require("/lib/lib_mining")
local lib_itemTypes = require("/lib/item_types")
local lib_move = require("/lib/move")

local loadingRadius = 90

-- Function to drop unwanted items
function dropUnwantedItems()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            if lib_itemTypes.isBlockNameInList(item.name,lib_itemTypes.unwantedItems) then
                turtle.dropDown()
            end
        end
    end
    turtle.select(1)
end

-- Function to spin and check/dig key minerals
function spinAndDigMinerals()
    for i = 1, 4 do
        local success, block = turtle.inspect()
        if success and lib_itemTypes.isBlockNameInList(block.name,lib_itemTypes.keyMinerals) then
            turtle.dig()
            print("Found and dug " .. block.name)
        end
        turtle.turnRight()
    end
end

-- Function to deposit items into a chest in front of the turtle
function depositItems()
    -- Loop through all turtle slots except for slot 1 (empty bucket)
    for slot = 2, 16 do
        turtle.select(slot)
        local itemCount = turtle.getItemCount(slot)

        -- If there are items in the slot, try to drop them into the chest
        if itemCount > 0 then
            if not turtle.drop() then
                print ("Chest is full. Could not deposit all items." )
                return false
            else
                print ("debug depositted")
            end
        end
    end

    -- If all items were deposited successfully
    print("Deposit Successful.")
    return true
end

-- Function to dig down until lava or bedrock is found
function spinMineDown(maxDepth)
    if maxDepth == nil then
        maxDepth = 500
    end

    local depth = 0
    while depth <= maxDepth do
        spinAndDigMinerals()

        if turtle.detectDown() then
            turtle.digDown()
        end

        local success, block = turtle.inspectDown()
        if success then
            if block.name == "minecraft:lava" then
                -- Found lava, use bucket to collect it
                turtle.select(1)
                turtle.refuel()
                turtle.placeDown()
            end
        end

        -- Move down and increase depth counter
        if turtle.down() then
            depth = depth + 1
        else
            print("Cannot move down, something is blocking the way.")
            return false, depth
        end
    end
    return true, depth
end

-- Function to return to the original Z level
function returnToSurface(depth)
    for i = 1, depth do
        if not turtle.up() then
            print("Cannot move up, something is blocking the way.")
            break
        end
    end
    print("depth: " .. depth)
end

function stripMineMacro(distX, distY, maxDepth)

    if distX > 30 then
        distX = 30
        print("max grid clamped to 30")
    end
    if distY > 30 then
        distY = 30
        print("max grid clamped to 30")
    end

    --TODO: could loop refueling here
    lib_move.refuel()

    local moveMacro = "FFRFL"
    lib_move.clearMoveMemory()
    
    --could comment this out to leave more of an hq area
    --local tsuccess, tdepth = spinMineDown(maxDepth)
    --returnToSurface(tdepth)
    --dropUnwantedItems()

    for y = 1, distY do
        for x = 1, distX do

            local success, depth = spinMineDown(maxDepth)
            returnToSurface(depth)
            dropUnwantedItems()

            if x == distX then
                break
            end

            lib_move.macroMove(moveMacro,true,true)

            if not lib_mining.hasEmptySlot() then
                --return to chest, deposit, and return to mining position
                lib_move.memPlayback(true, true)
                --chest on left
                turtle.turnLeft()
                depositItems()
                turtle.turnRight()
                lib_move.memPlayback(false,true)
            end
        end

        if y == distY then
            break
        end
        
        lib_move.memPlayback(true, true)
        lib_move.clearMoveMemory()

        lib_move.charMove("R", true, true)
        for dy = 1, y do
            lib_move.macroMove(moveMacro,true,true)
        end
        lib_move.charMove("L", true, true)
    end
    lib_move.memPlayback(true, true)
    turtle.turnLeft()
    depositItems()
    turtle.turnRight()
    lib_move.clearMoveMemory()
end

-- Capture arguments passed to the script
local args = {...}

local fuelBefore = turtle.getFuelLevel()
print("Fuel level: " .. fuelBefore)

-- Convert arguments to numbers
local arg1 = tonumber(args[1])
local arg2 = tonumber(args[2])
local arg3 = tonumber(args[3])

-- Check if all arguments were provided and are valid integers
if arg1 and arg2 and arg3 then
    local fuelEstimate = arg1 * arg2 * 2 * arg3
    print("Rough fuel use estimate: " .. fuelEstimate)
    print("Rough time estimate: " .. "TODO")
    stripMineMacro(arg1, arg2, arg3)
    print("actual fuel usage: " .. (fuelBefore - turtle.getFuelLevel()))
    --lib_move.moveMacro("FRFRFRFR")
else
    print("Please provide arguments: x, y, maxDepth, where x and y are approximately 1/3 of target mining distance in each direction")
end