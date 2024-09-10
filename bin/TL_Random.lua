local lib_mining = require("/lib/lib_mining")
local lib_itemTypes = require("/lib/item_types")
local lib_move = require("/lib/move")
local lib_farming = require("/lib/farming")

function toFile(string)
    local file = fs.open("debugFile", "w")
    file.writeLine(string)
    file.close()
end

-- Helper function to compute Euclidean distance between two points
local function distance(a, b)
    return math.sqrt((a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2)
end

-- Nearest neighbor TSP sorting function
function nearest_neighbor_sort(blocks)
    local sortedBlocks = {}
    local currentPos = {0, 0, 0} -- Start at origin (0, 0, 0)
    
    -- Keep track of visited blocks
    local visited = {}
    for i = 1, #blocks do
        visited[i] = false
    end

    -- Repeat until all blocks are visited
    for _ = 1, #blocks do
        local nearestBlock = nil
        local nearestDistance = math.huge
        local nearestIndex = -1

        -- Find the nearest unvisited block
        for i, block in ipairs(blocks) do
            if not visited[i] then
                local dist = distance(currentPos, block)
                if dist < nearestDistance then
                    nearestDistance = dist
                    nearestBlock = block
                    nearestIndex = i
                end
            end
        end

        -- Visit the nearest block and mark it as visited
        table.insert(sortedBlocks, nearestBlock)
        visited[nearestIndex] = true
        currentPos = nearestBlock -- Move to the new current position
    end

    return sortedBlocks
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

function paraboloid(x, z)
    --35 stable but stubby feet
    local tempY = 37 - 0.112 * (math.pow(x,2) + math.pow(z,2))
    return tempY
end

-- Function to calculate the Euclidean distance between a point and the surface
function calculateDistance(x, z, x0, z0, y0, f)
    local y = f(x, z)  -- Calculate the surface height at (x, z)
    return math.sqrt((x - x0)^2 + (z - z0)^2 + (y - y0)^2)  -- Euclidean distance
end

-- Coordinate descent function with multiple starting configurations
function findClosestPointCoordinateDescent(x0, z0, y0, f, initialStep, tolerance, maxIterations)
    if initialStep == nil then
        initialStep = 0.25
        tolerance = 0.001
        maxIterations = 200
    end

    -- Define step configurations for 4 possible directions
    local stepConfigs = {
        {initialStep, initialStep},     -- (x, z)
        {-initialStep, initialStep},    -- (-x, z)
        {-initialStep, -initialStep},   -- (-x, -z)
        {initialStep, -initialStep}     -- (x, -z)
    }

    local bestOverallDistance = math.huge
    local bestX, bestZ = x0, z0  -- Store the best coordinates found

    -- Run the coordinate descent for each configuration
    for configIndex, config in ipairs(stepConfigs) do
        local stepX, stepZ = config[1], config[2]
        local x, z = x0, z0

        -- Start with the initial distance for this configuration
        local bestDistance = calculateDistance(x, z, x0, z0, y0, f)

        for iter = 1, maxIterations do
            local updated = false

            -- Update both x and z simultaneously
            local newDistanceX = calculateDistance(x + stepX, z, x0, z0, y0, f)
            local newDistanceZ = calculateDistance(x, z + stepZ, x0, z0, y0, f)

            -- Move in the x direction if it improves
            if newDistanceX < bestDistance then
                x = x + stepX
                bestDistance = newDistanceX
                updated = true
            else
                stepX = -stepX / 2
            end

            -- Move in the z direction if it improves
            if newDistanceZ < bestDistance then
                z = z + stepZ
                bestDistance = newDistanceZ
                updated = true
            else
                stepZ = -stepZ / 2
            end

            -- Check if both step sizes are small enough to stop
            if math.abs(stepX) < tolerance and math.abs(stepZ) < tolerance then
                --print("Configuration " .. configIndex .. " converged after " .. iter .. " iterations.")
                break
            end

            if not updated then
                --print("Configuration " .. configIndex .. " no significant update after " .. iter .. " iterations.")
                break
            end
        end

        -- Keep track of the overall best distance and corresponding coordinates
        if bestDistance < bestOverallDistance then
            bestOverallDistance = bestDistance
            bestX, bestZ = x, z
        end
    end

    -- Return the best distance found across all configurations
    return bestOverallDistance, bestX, bestZ
end

function placeDownWithWraparound()
    local startSlot = turtle.getSelectedSlot()  -- Get the current selected slot
    local currentSlot = startSlot
    turtle.digDown()

    repeat
        if turtle.placeDown() then 
            return true 
        else
            currentSlot = (currentSlot % 16) + 1
            turtle.select(currentSlot)
        end
    until currentSlot == startSlot

    print("No item could be placed.")
    return false
end

function checkPointIn(x,z,y, f,proximity)
    local minDist = findClosestPointCoordinateDescent(x, z, y, f)
    if minDist <= proximity then
        return true
    end
end

function plotStepFunction(f, proximity)
    if proximity == nil then
        proximity = 0.5
        f = paraboloid
    end

    local x,z,y = lib_move.getPos()
    local minDist = findClosestPointCoordinateDescent(x, z, y, f)
    if minDist <= proximity then
        placeDownWithWraparound()
        --todo: wait for more material here
        --todo: different material selection (inventory rng)
    end
end

function clear3D(rad,height)
    for h = 1, height + 1 do
        lib_move.spiralOut(rad)
        lib_move.goUp(true)
    end
end

function plot3D(rad,height)
    --equation: y = x^2 + z^2
    lib_move.setTether(64)
    lib_move.setHome()
    for h = 1, height + 1 do
        lib_move.spiralOut(rad, plotStepFunction)
        lib_move.goUp(true)
    end
    lib_move.pathTo(0,0,0,false)
end

function plot3D_v2(rad, height)
    lib_move.setTether(64)
    lib_move.setHome()
    
    local blocksPlaced = 0
    local lastRefill = 0
    local refillLevel = 750

    -- Iterate through height layers
    for h = 1, height + 1 do
        local blocksToPlace = {}

        -- Compute all blocks to place at height 'h'
        for x = -rad, rad do
            for z = -rad, rad do
                if checkPointIn(x,z,h, paraboloid,0.55) then
                    -- Add coordinates to the list of blocks to place
                    table.insert(blocksToPlace, {x, h, z})
                end
            end
        end

        if blocksPlaced + #blocksToPlace >= lastRefill + refillLevel then
            lib_move.goTo(0, 0, h)

            print("refill mats")
            io.read()
            lastRefill = blocksPlaced
        end
        blocksPlaced = blocksPlaced + #blocksToPlace

        blocksToPlace = nearest_neighbor_sort(blocksToPlace)

        -- Go to each block and place it
        for _, coords in ipairs(blocksToPlace) do
            local x, y, z = coords[1], coords[2], coords[3]
            lib_move.goTo(x, z, y)

            placeDownWithWraparound()
        end
        
        -- Move up after finishing the current layer
        lib_move.goUp(true)
    end

    -- Return to home (0, 0, 0) after completing the entire structure
    lib_move.pathTo(0, 0, 0, false)
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
        lib_farming.sweepUp(2)
        turtle.down()
    elseif arg1 == 4 then
        lib_move.goForward(true)
        inspectDownToPrint()
    elseif arg1 == 5 then
        print("vein miner")
        lib_move.setHome()
        lib_move.setTether(64,true)

        local dir = args[2]
        if dir == "u" then
            while true do
                local has_block, data = turtle.inspectUp()
                if has_block then
                    break
                end
                lib_move.goUp(true)
            end
        elseif dir == "f" then
            while true do
                local has_block, data = turtle.inspect()
                if has_block then
                    break
                end
                lib_move.goForward(true)
            end
        else
            --assume turtle is touching desired mat on some side
        end

        local targetBlocks = {}
        for i = 3, #args do
            table.insert(targetBlocks, args[i])
        end

        lib_move.floodFill(targetBlocks, false)

        lib_move.goHome()

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

        lib_move.setHome()
        lib_move.setTether(64,true)

        lib_move.floodFill(blocks,true, bucketUp)

        lib_move.goHome()
    elseif arg1 == 9 then
        plot3D_v2(13,40)
    elseif arg1 == 10 then
        clear3D(13,45)
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
    print("9: 3d plot demo")
    print("10: 3d clear demo")
end