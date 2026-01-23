--[[
excavate_chunk.lua - Excavates layers of the chunk the turtle is in

Usage:
  excavate_chunk [start]:[stop]

Examples:
  excavate_chunk :-56       -- Start at current Y, excavate down to Y=-56
  excavate_chunk 30:-56     -- Move to Y=30 first, then excavate down to Y=-56
  excavate_chunk            -- No args: excavate 5 layers from current position

Expected setup:
- Turtle starts facing a wired modem block
- This position is recorded as "home"
- Uses GPS to determine chunk boundaries
- Moves to every square in the chunk layer and digs down 1 block
- Skips squares blocked by "computercraft:cable"
]]

local move = require("/lib/move")
local imv = require("/bin/imv")

-- Configuration
local CHUNK_SIZE = 16
local CABLE_BLOCK = "computercraft:cable"

-- Parse command line arguments
local args = {...}
local startY = nil  -- nil means use current Y
local stopY = nil   -- nil means use default (5 layers)

local function parseArgs()
    if #args == 0 then
        return true  -- No args, use defaults
    end

    local arg = args[1]
    -- Pattern: [start]:stop  e.g., "30:-56" or ":-56"
    local s, e = arg:match("^(-?%d*):(-?%d+)$")

    if e then
        stopY = tonumber(e)
        if s and s ~= "" then
            startY = tonumber(s)
        end
        return true
    end

    print("Invalid argument: " .. arg)
    print("Usage: excavate_chunk [start]:[stop]")
    print("  :-56      Start at current Y, dig to Y=-56")
    print("  30:-56    Start at Y=30, dig to Y=-56")
    return false
end

-- State
local homeX, homeY, homeZ, homeFacing
local chunkStartX, chunkStartZ
local chunkEndX, chunkEndZ

-- Get GPS position with retry
local function getGPSPosition()
    local maxAttempts = 5
    local attemptDelay = 2

    for attempt = 1, maxAttempts do
        local x, y, z = gps.locate(5)
        if x then
            return x, y, z
        else
            if attempt < maxAttempts then
                sleep(attemptDelay)
            end
        end
    end

    return nil
end

-- Calculate facing from movement delta
local function deltaToFacing(dx, dz)
    -- facing: 0=north(-z), 1=east(+x), 2=south(+z), 3=west(-x)
    if dz == -1 then return 0
    elseif dx == 1 then return 1
    elseif dz == 1 then return 2
    elseif dx == -1 then return 3
    end
    return nil
end

-- Get turtle's current facing direction by moving and checking GPS delta
-- Tries multiple directions if forward is blocked (e.g., by a modem)
local function determineFacing()
    local x1, y1, z1 = getGPSPosition()
    if not x1 then
        return nil
    end

    -- Try each direction: forward, right, back, left (0, 1, 2, 3 turns from original)
    for turns = 0, 3 do
        if turtle.forward() then
            local x2, y2, z2 = getGPSPosition()
            turtle.back()

            -- Turn back to original facing using shorter direction
            if turns == 1 then
                turtle.turnLeft()
            elseif turns == 2 then
                turtle.turnLeft()
                turtle.turnLeft()
            elseif turns == 3 then
                turtle.turnRight()  -- 1 right is shorter than 3 lefts
            end

            if x2 then
                local dx = x2 - x1
                local dz = z2 - z1

                -- Get facing after the turns we made
                local movedFacing = deltaToFacing(dx, dz)
                if movedFacing then
                    -- Calculate original facing: subtract the turns we made
                    local originalFacing = (movedFacing - turns) % 4
                    return originalFacing
                end
            end
        else
            -- Couldn't move forward, turn right and try again
            turtle.turnRight()
        end
    end

    -- If we get here, we couldn't move in any direction
    print("ERROR: Could not move in any direction to determine facing")
    return nil
end

-- Convert facing to move.lua direction format (xDir, zDir)
local function facingToDir(facing)
    -- move.lua: xDir=1 means +X, zDir=1 means +Z
    -- facing: 0=north(-z), 1=east(+x), 2=south(+z), 3=west(-x)
    if facing == 0 then return 0, -1      -- north: -Z
    elseif facing == 1 then return 1, 0   -- east: +X
    elseif facing == 2 then return 0, 1   -- south: +Z
    elseif facing == 3 then return -1, 0  -- west: -X
    end
    return 1, 0 -- default
end

-- Calculate chunk boundaries from world coordinates
local function calculateChunkBounds(x, z)
    local startX = math.floor(x / CHUNK_SIZE) * CHUNK_SIZE
    local startZ = math.floor(z / CHUNK_SIZE) * CHUNK_SIZE
    local endX = startX + CHUNK_SIZE - 1
    local endZ = startZ + CHUNK_SIZE - 1
    return startX, startZ, endX, endZ
end

-- Check if the block below is a cable
local function isCableBelow()
    local success, data = turtle.inspectDown()
    if success and data.name == CABLE_BLOCK then
        return true
    end
    return false
end

-- Check if the block in front is a cable
local function isCableAhead()
    local success, data = turtle.inspect()
    if success and data.name == CABLE_BLOCK then
        return true
    end
    return false
end

-- Initialize home position
local function initializeHome()
    -- Get GPS coordinates
    local x, y, z = getGPSPosition()
    if not x then
        print("ERROR: Could not get GPS position")
        return false
    end

    -- Get facing
    local facing = determineFacing()
    if not facing then
        print("ERROR: Could not determine facing direction")
        return false
    end

    homeX, homeY, homeZ, homeFacing = x, y, z, facing

    -- Calculate chunk boundaries
    chunkStartX, chunkStartZ, chunkEndX, chunkEndZ = calculateChunkBounds(homeX, homeZ)

    -- Set up move library
    local xDir, zDir = facingToDir(homeFacing)
    move.setHome()

    print(string.format("Home: %d,%d,%d Chunk: X[%d-%d] Z[%d-%d]",
        homeX, homeY, homeZ, chunkStartX, chunkEndX, chunkStartZ, chunkEndZ))
    return true
end

-- Movement functions that track absolute position
local currentX, currentY, currentZ, currentFacing

local function moveForward()
    -- Check for cable
    if isCableAhead() then
        return false, "cable"
    end

    while turtle.detect() do
        if not turtle.dig() then
            return false, "undiggable"
        end
        sleep(0.5) -- Wait for falling blocks
    end

    if turtle.forward() then
        if currentFacing == 0 then currentZ = currentZ - 1
        elseif currentFacing == 1 then currentX = currentX + 1
        elseif currentFacing == 2 then currentZ = currentZ + 1
        elseif currentFacing == 3 then currentX = currentX - 1
        end
        return true
    end
    return false, "blocked"
end

local function turnRight()
    turtle.turnRight()
    currentFacing = (currentFacing + 1) % 4
end

local function turnLeft()
    turtle.turnLeft()
    currentFacing = (currentFacing - 1) % 4
    if currentFacing < 0 then currentFacing = 3 end
end

local function turnTo(direction)
    if currentFacing == direction then
        return
    end

    -- Calculate shortest turn direction
    local rightTurns = (direction - currentFacing) % 4
    local leftTurns = (currentFacing - direction) % 4

    if leftTurns <= rightTurns then
        for i = 1, leftTurns do
            turnLeft()
        end
    else
        for i = 1, rightTurns do
            turnRight()
        end
    end
end

-- Move to specific X,Z coordinates (staying at same Y)
local function moveTo(targetX, targetZ)
    -- Move in X direction
    while currentX ~= targetX do
        local dir = currentX < targetX and 1 or 3
        turnTo(dir)
        local success, reason = moveForward()
        if not success then
            return false, reason
        end
    end

    -- Move in Z direction
    while currentZ ~= targetZ do
        local dir = currentZ < targetZ and 2 or 0
        turnTo(dir)
        local success, reason = moveForward()
        if not success then
            return false, reason
        end
    end

    return true
end

-- Dig down one block at current position
local function digDownOne()
    if isCableBelow() then
        return false
    end

    if turtle.detectDown() then
        return turtle.digDown()
    end
    -- No block below, that's fine
    return true
end

-- Try to move in a direction, returns true if successful
local function tryMove(dir)
    turnTo(dir)
    local success, reason = moveForward()
    return success, reason
end

-- Move down one block, digging if necessary
local function goDown()
    if turtle.detectDown() then
        local success, data = turtle.inspectDown()
        if success and data.name == CABLE_BLOCK then
            print("ERROR: Cable below - cannot descend")
            return false
        end
        if not turtle.digDown() then
            print("ERROR: Cannot dig down")
            return false
        end
    end

    if turtle.down() then
        currentY = currentY - 1
        return true
    end

    print("ERROR: Cannot move down")
    return false
end

-- Move up one block, digging if necessary
local function goUp()
    if turtle.detectUp() then
        if not turtle.digUp() then
            print("ERROR: Cannot dig up")
            return false
        end
    end

    if turtle.up() then
        currentY = currentY + 1
        return true
    end

    print("ERROR: Cannot move up")
    return false
end

-- Return to home Y level
local function returnToHomeY()
    while currentY < homeY do
        if not goUp() then
            return false
        end
    end
    return true
end

-- Descend to a specific Y level
local function descendToY(targetY)
    while currentY > targetY do
        if not goDown() then
            return false
        end
    end
    return true
end

-- Return to home position, navigating around obstacles
local function returnHome()

    local maxAttempts = 256 -- Prevent infinite loops
    local attempts = 0

    while (currentX ~= homeX or currentZ ~= homeZ) and attempts < maxAttempts do
        attempts = attempts + 1
        local moved = false

        -- Determine preferred directions
        local xDir = nil
        local zDir = nil

        if currentX < homeX then xDir = 1      -- east
        elseif currentX > homeX then xDir = 3  -- west
        end

        if currentZ < homeZ then zDir = 2      -- south
        elseif currentZ > homeZ then zDir = 0  -- north
        end

        -- Try X direction first
        if xDir and not moved then
            local success, reason = tryMove(xDir)
            if success then
                moved = true
            end
        end

        -- Try Z direction
        if zDir and not moved then
            local success, reason = tryMove(zDir)
            if success then
                moved = true
            end
        end

        -- If direct routes blocked, try perpendicular detour
        if not moved then
            -- Try all 4 directions to find any way to move
            local dirs = {0, 1, 2, 3}
            for _, dir in ipairs(dirs) do
                local success, reason = tryMove(dir)
                if success then
                    moved = true
                    break
                end
            end
        end

        -- If completely stuck, we have a problem
        if not moved then
            print(string.format("ERROR: Stuck at %d, %d - cannot return home", currentX, currentZ))
            break
        end
    end

    if currentX == homeX and currentZ == homeZ then
        turnTo(homeFacing)
        return true
    else
        print(string.format("WARNING: Could not reach home. At: %d,%d", currentX, currentZ))
        return false
    end
end

-- Dump entire inventory to wired network
local function dumpInventory()
    local count, err = imv.move("./*:++", "../")
    if count and count > 0 then
        print(string.format("Dumped %d items.", count))
    end
    turtle.select(1)
    return count or 0
end

-- Pull lava buckets from network and refuel
local function refuelFromNetwork()
    local fuelLevel = turtle.getFuelLevel()
    local fuelLimit = turtle.getFuelLimit()

    if fuelLevel == "unlimited" or fuelLevel > fuelLimit * 0.8 then
        return true
    end

    -- Calculate buckets needed
    local bucketsNeeded = math.ceil((fuelLimit - fuelLevel) / 1000)
    bucketsNeeded = math.min(bucketsNeeded, 16)

    -- Pull lava buckets from network
    local count, err = imv.move(string.format("../lava_bucket:%d", bucketsNeeded), "./")

    if count and count > 0 then
        -- Refuel with lava buckets
        local bucketsUsed = 0
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and item.name == "minecraft:lava_bucket" then
                turtle.select(slot)
                if turtle.refuel() then
                    bucketsUsed = bucketsUsed + 1
                end
            end
        end
        print(string.format("Refueled with %d lava buckets. Fuel: %d", bucketsUsed, turtle.getFuelLevel()))
    end

    turtle.select(1)
    return true
end

-- Main excavation routine using serpentine pattern
local function excavateLayer()
    local blocksDug = 0
    local blocksSkipped = 0

    -- Serpentine pattern through the chunk
    local direction = 1  -- 1 = positive Z, -1 = negative Z

    for x = chunkStartX, chunkEndX do
        local zStart, zEnd, zStep

        if direction == 1 then
            zStart, zEnd, zStep = chunkStartZ, chunkEndZ, 1
        else
            zStart, zEnd, zStep = chunkEndZ, chunkStartZ, -1
        end

        for z = zStart, zEnd, zStep do
            -- Try to move to this position
            local success, reason = moveTo(x, z)

            if success then
                if digDownOne() then
                    blocksDug = blocksDug + 1
                end
            else
                blocksSkipped = blocksSkipped + 1
            end

            -- Refuel check
            if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 100 then
                move.refuel()
            end
        end

        -- Alternate direction for serpentine pattern
        direction = -direction
    end

    print(string.format("Layer complete. Dug: %d, Skipped: %d", blocksDug, blocksSkipped))
end

-- Main function
local function main()
    -- Parse command line arguments
    if not parseArgs() then
        return
    end

    -- Check fuel
    local fuel = turtle.getFuelLevel()
    if fuel ~= "unlimited" and fuel < 500 then
        print("WARNING: Low fuel (" .. fuel .. "). Consider refueling first.")
        print("Press any key to continue or Ctrl+T to terminate...")
        os.pullEvent("key")
    end

    -- Initialize
    if not initializeHome() then
        print("Failed to initialize. Aborting.")
        return
    end

    -- Set current position to home
    currentX, currentY, currentZ, currentFacing = homeX, homeY, homeZ, homeFacing

    -- Add cable to move library blacklist (won't dig through cables)
    move.addBlacklist(CABLE_BLOCK)

    -- Determine actual start and stop Y levels
    local actualStartY = startY or currentY
    local actualStopY = stopY or (currentY - 5)  -- Default: 5 layers down
    local totalLayers = actualStartY - actualStopY + 1

    if actualStartY <= actualStopY then
        print("ERROR: Start Y must be greater than stop Y (we dig downward)")
        print(string.format("  Start: %d, Stop: %d", actualStartY, actualStopY))
        return
    end

    print(string.format("Excavating Y=%d to Y=%d (%d layers)", actualStartY, actualStopY, totalLayers))

    -- If startY specified and we need to descend to it first
    if startY and currentY > startY then
        while currentY > startY do
            if not goDown() then
                print("ERROR: Cannot descend to starting level")
                return
            end
        end
    end

    -- Loop through each layer until we reach stopY
    local layerCount = 0
    while currentY >= actualStopY do
        layerCount = layerCount + 1
        local workingY = currentY  -- Remember the layer we're working on
        print(string.format("Layer %d/%d (Y=%d)", layerCount, totalLayers, currentY))

        -- Run excavation for this layer
        excavateLayer()

        -- Return home (X,Z position) then go up to home Y for wired modem access
        returnHome()
        returnToHomeY()

        -- Dump inventory, refuel, dump empty buckets
        dumpInventory()
        refuelFromNetwork()
        dumpInventory()  -- Empty buckets

        -- Check if we need to continue to more layers
        if workingY > actualStopY then
            descendToY(workingY - 1)
        else
            break  -- Reached the stop level
        end
    end

    -- Make sure we're at home position (should already be there after last dump)
    if currentY ~= homeY then
        returnToHomeY()
    end
    turnTo(homeFacing)

    print(string.format("Complete: %d layers", layerCount))
end

-- Run
main()
