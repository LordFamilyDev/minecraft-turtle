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

-- Global variable to keep track of facing direction
local currentFacing

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
local function findNearestOre(ores, currentX, currentY, currentZ)
    local nearestOre = nil
    local minDistance = math.huge
    for _, ore in ipairs(ores) do
        local distance = manhattanDistance(currentX, currentY, currentZ, ore.x, ore.y, ore.z)
        if distance < minDistance then
            minDistance = distance
            nearestOre = ore
        end
    end
    return nearestOre, minDistance
end

-- New movement functions
local function moveUp()
    while turtle.detectUp() do
        if not turtle.digUp() then
            print("Cannot dig up")
            return false
        end
    end
    return turtle.up()
end

local function moveDown()
    while turtle.detectDown() do
        if not turtle.digDown() then
            print("Cannot dig down")
            return false
        end
    end
    return turtle.down()
end

local function moveForward()
    while turtle.detect() do
        if not turtle.dig() then
            print("Cannot dig forward")
            return false
        end
    end
    return turtle.forward()
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
    local currentX, currentY, currentZ, _ = getPositionAndFacing()
    if not currentX then return false end
    
    -- Move in X direction
    while currentX ~= targetX do
        if currentX < targetX then
            turnTo(1)  -- Face east
            if not moveForward() then return false end
        else
            turnTo(3)  -- Face west
            if not moveForward() then return false end
        end
        currentX, currentY, currentZ, _ = getPositionAndFacing()
        if not currentX then return false end
    end
    
    -- Move in Z direction
    while currentZ ~= targetZ do
        if currentZ < targetZ then
            turnTo(2)  -- Face south
            if not moveForward() then return false end
        else
            turnTo(0)  -- Face north
            if not moveForward() then return false end
        end
        currentX, currentY, currentZ, _ = getPositionAndFacing()
        if not currentX then return false end
    end
    
    -- Move in Y direction
    while currentY < targetY do
        if not moveUp() then return false end
        currentX, currentY, currentZ, _ = getPositionAndFacing()
        if not currentX then return false end
    end
    while currentY > targetY do
        if not moveDown() then return false end
        currentX, currentY, currentZ, _ = getPositionAndFacing()
        if not currentX then return false end
    end
    
    return true
end

-- Function to return home
local function returnHome(homeX, homeY, homeZ)
    local currentX, currentY, currentZ, _ = getPositionAndFacing()
    if not currentX then return false end
    
    -- Move in X and Z directions first
    if not moveTo(homeX, currentY, homeZ) then
        return false
    end
    
    -- Then adjust Y (height)
    currentX, currentY, currentZ, _ = getPositionAndFacing()
    if not currentX then return false end
    while currentY < homeY do
        if not moveUp() then return false end
        _, currentY, _, _ = getPositionAndFacing()
        if not currentY then return false end
    end
    while currentY > homeY do
        if not moveDown() then return false end
        _, currentY, _, _ = getPositionAndFacing()
        if not currentY then return false end
    end
    
    return true
end

-- Function to dump unwanted items
local function dumpUnwantedItems()
    print("Dumping unwanted items...")
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
    turtle.select(1)
    print("Dump complete.")
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
    -- Record starting position and initialize facing
    local homeX, homeY, homeZ, homeFacing = getPositionAndFacing()
    if not homeX then
        errorMsg("Could not get starting position. Aborting.")
        return
    end
    currentFacing = homeFacing
    print("Starting position: " .. homeX .. "," .. homeY .. "," .. homeZ .. ", facing: " .. homeFacing)

    -- Scan for ores
    local ores = scanForOres()
    -- wait for user input before mining
    print("Press any key to start mining...")
    os.pullEvent("key")

    -- Mine ores
    while #ores > 0 do
        local currentX, currentY, currentZ, _ = getPositionAndFacing()
        if not currentX then
            errorMsg("Lost position during mining. Attempting to return home.")
            break
        end
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
        local finalX, finalY, finalZ, finalFacing = getPositionAndFacing()
        if finalX then
            print("Final position: " .. finalX .. "," .. finalY .. "," .. finalZ .. ", facing: " .. finalFacing)
        else
            print("Unable to determine final position.")
        end
    end

    print("Mining operation complete.")
end

-- Run the main function
main()