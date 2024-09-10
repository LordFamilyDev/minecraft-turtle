-- Load required library
local blockAPI = require("/lib/lib_block")

-- List of ores to scan for
local targetOres = {"coal", "diamond", "iron", "gold", "redstone", "emerald"}

-- List of items to dump
local dumpItems = {
    "minecraft:cobblestone",
    "minecraft:granite",
    "minecraft:andesite",
    "minecraft:diorite",
    "minecraft:cobbled_deepslate",
    "minecraft:tuff"
}

-- Global variables to keep track of position and facing
local currentX, currentY, currentZ, currentFacing

-- Function to print error messages
local function errorMsg(message)
    print("ERROR: " .. message)
end

-- Function to get current GPS position and facing with retry
local function getPositionAndFacing()
    local maxAttempts = 5
    local attemptDelay = 2 -- seconds

    for attempt = 1, maxAttempts do
        local result, error = blockAPI.getTurtlePositionAndFacing()
        if result then
            return result.x, result.y, result.z, result.facing
        else
            print("Attempt " .. attempt .. " failed to get position and facing: " .. tostring(error))
            if attempt < maxAttempts then
                print("Retrying in " .. attemptDelay .. " seconds...")
                sleep(attemptDelay)
            end
        end
    end

    errorMsg("Failed to get position and facing after " .. maxAttempts .. " attempts")
    return nil
end

-- Function to check if a block name is in the target ores list
local function isTargetOre(blockName)
    for _, ore in ipairs(targetOres) do
        if blockName:find(ore) then
            return true
        end
    end
    return false
end

-- Function to scan for ores
local function scanForOres()
    print("Scanning for ores...")
    local oreData = blockAPI.chunkScan(table.concat(targetOres, " "))
    local allOres = {}
    for ore, positions in pairs(oreData) do
        for _, pos in ipairs(positions) do
            table.insert(allOres, {ore = ore, x = pos[1], y = pos[2], z = pos[3]})
        end
    end
    print("Scan complete. Found " .. #allOres .. " ore blocks.")
    return allOres
end

-- Function to calculate Manhattan distance
local function manhattanDistance(x1, y1, z1, x2, y2, z2)
    return math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)
end

-- Function to find the nearest ore
local function findNearestOre(ores, x, y, z)
    local nearestOre = nil
    local minDistance = math.huge
    for _, ore in ipairs(ores) do
        local distance = manhattanDistance(x, y, z, ore.x, ore.y, ore.z)
        if distance < minDistance then
            minDistance = distance
            nearestOre = ore
        end
    end
    return nearestOre, minDistance
end

-- New movement functions that update position
local function moveUp()
    while turtle.detectUp() do
        local success, data = turtle.inspectUp()
        if success and data.name == "minecraft:bedrock" then
            return false
        end
        if not turtle.digUp() then
            print("Cannot dig up")
            return false
        end
    end
    if turtle.up() then
        currentY = currentY + 1
        return true
    end
    return false
end

local function moveDown()
    while turtle.detectDown() do
        local success, data = turtle.inspectDown()
        if success and data.name == "minecraft:bedrock" then
            return false
        end
        if not turtle.digDown() then
            print("Cannot dig down")
            return false
        end
    end
    if turtle.down() then
        currentY = currentY - 1
        return true
    end
    return false
end

local function moveForward()
    while turtle.detect() do
        local success, data = turtle.inspect()
        if success and data.name == "minecraft:bedrock" then
            return false
        end
        if not turtle.dig() then
            print("Cannot dig forward")
            return false
        end
    end
    if turtle.forward() then
        if currentFacing == 0 then currentZ = currentZ - 1
        elseif currentFacing == 1 then currentX = currentX + 1
        elseif currentFacing == 2 then currentZ = currentZ + 1
        elseif currentFacing == 3 then currentX = currentX - 1
        end
        return true
    end
    return false
end

-- Function to turn the turtle right
local function turnRight()
    turtle.turnRight()
    currentFacing = (currentFacing + 1) % 4
end

-- Function to turn the turtle left
local function turnLeft()
    turtle.turnLeft()
    currentFacing = (currentFacing - 1) % 4
end

-- Function to turn the turtle to a specific direction
local function turnTo(direction)
    while currentFacing ~= direction do
        turnRight()
    end
end

-- Function to move to a specific position
local function moveTo(targetX, targetY, targetZ)
    local function tryMove(moveFunc, condition)
        local attempts = 0
        while condition() and attempts < 5 do
            if not moveFunc() then
                attempts = attempts + 1
                if attempts == 5 then
                    return false
                end
                -- Try to move up if blocked
                for i = 1, 5 do
                    if not moveUp() then break end
                end
            end
        end
        return true
    end

    -- Move in X direction
    if not tryMove(
        function() turnTo(currentX < targetX and 1 or 3) return moveForward() end,
        function() return currentX ~= targetX end
    ) then return false end

    -- Move in Z direction
    if not tryMove(
        function() turnTo(currentZ < targetZ and 2 or 0) return moveForward() end,
        function() return currentZ ~= targetZ end
    ) then return false end

    -- Move in Y direction
    while currentY < targetY do
        if not moveUp() then return false end
    end
    while currentY > targetY do
        if not moveDown() then return false end
    end

    return true
end

-- Function to return home
local function returnHome(homeX, homeY, homeZ)
    return moveTo(homeX, homeY, homeZ)
end

-- Improved function to dump unwanted items and de-duplicate stacks
local function dumpUnwantedItems()
    print("Dumping unwanted items and optimizing inventory...")
    
    -- First, dump unwanted items
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            for _, dumpItem in ipairs(dumpItems) do
                if item.name == dumpItem then
                    turtle.select(slot)
                    turtle.drop()
                    break
                end
            end
        end
    end
    
    -- Then, de-duplicate and consolidate stacks
    local inventory = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if not inventory[item.name] then
                inventory[item.name] = {slot = slot, count = item.count}
            else
                -- Move items to consolidate
                turtle.select(slot)
                local moved = turtle.transferTo(inventory[item.name].slot)
                inventory[item.name].count = inventory[item.name].count + moved
                if turtle.getItemCount(slot) > 0 then
                    -- If the first slot is full, start a new stack
                    inventory[item.name] = {slot = slot, count = turtle.getItemCount(slot)}
                end
            end
        end
    end
    
    turtle.select(1)
    print("Inventory optimization complete.")
end

-- Function to mine an ore
local function mineOre(ore)
    print("Mining " .. ore.ore .. " at " .. ore.x .. "," .. ore.y .. "," .. ore.z)
    if moveTo(ore.x, ore.y, ore.z) then
        -- We're at the ore position, so we've mined it
        print("Mined successfully.")
        return true
    else
        print("Failed to reach ore position.")
        return false
    end
end

-- Main function
local function main()
    -- Get starting position and initialize facing
    local homeX, homeY, homeZ, homeFacing = getPositionAndFacing()
    if not homeX then
        errorMsg("Could not get starting position. Aborting.")
        return
    end
    currentX, currentY, currentZ, currentFacing = homeX, homeY, homeZ, homeFacing
    print("Starting position: " .. currentX .. "," .. currentY .. "," .. currentZ .. ", facing: " .. currentFacing)

    -- Scan for ores
    local ores = scanForOres()

    -- Wait for user input to start mining
    print("Press any key to start mining...")
    os.pullEvent("key")

    -- Mine ores
    while #ores > 0 do
        local nearestOre, distance = findNearestOre(ores, currentX, currentY, currentZ)
        
        if nearestOre then
            -- Check if we need to dump items before moving
            if distance > 5 then
                dumpUnwantedItems()
            end
            
            if mineOre(nearestOre) then
                -- Remove the mined ore from the list
                for i = #ores, 1, -1 do
                    if ores[i].x == nearestOre.x and ores[i].y == nearestOre.y and ores[i].z == nearestOre.z then
                        table.remove(ores, i)
                        break
                    end
                end
            else
                -- If mining failed, remove the ore from the list to avoid getting stuck
                print("Removing unreachable ore from the list.")
                for i = #ores, 1, -1 do
                    if ores[i].x == nearestOre.x and ores[i].y == nearestOre.y and ores[i].z == nearestOre.z then
                        table.remove(ores, i)
                        break
                    end
                end
            end
        else
            print("No more reachable ores.")
            break
        end
    end

    -- Return to starting position
    print("Returning to starting position...")
    if returnHome(homeX, homeY, homeZ) then
        print("Returned to starting position successfully.")
    else
        errorMsg("Failed to return to exact starting position.")
        print("Final position: " .. currentX .. "," .. currentY .. "," .. currentZ .. ", facing: " .. currentFacing)
    end

    print("Mining operation complete.")
end

-- Run the main function
main()