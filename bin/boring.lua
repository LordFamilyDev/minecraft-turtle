function refuelWithCoalOrCharcoal()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and (item.name == "minecraft:coal" or item.name == "minecraft:charcoal") then
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled with " .. item.name)
                return true
            end
        end
    end
    print("No coal or charcoal found in inventory")
    return false
end

-- Helper function to check if a block is lava or water
local function isFluid(blockName)
    return blockName == "minecraft:lava" or blockName == "minecraft:water"
end

-- Helper function to mine and collect loot, handling falling blocks
local function mineAndCollectWithFallingBlocks()
    while true do
        if turtle.detect() then
            turtle.dig()
            turtle.suck()
            -- Wait a moment for blocks to fall
            os.sleep(0.5)
        else
            -- No more blocks in front, we can stop digging
            break
        end
    end
end

-- Helper function to check if a block is a valuable ore
local function isValuableOre(blockName)
    return blockName == "minecraft:iron_ore" or 
           blockName == "minecraft:diamond_ore" or 
           blockName == "minecraft:coal_ore" or
           blockName == "minecraft:deepslate_iron_ore" or
           blockName == "minecraft:deepslate_diamond_ore" or
           blockName == "minecraft:deepslate_coal_ore"
end

-- Helper function to place cobblestone
local function placeCobble(placeFunc)
    local cobbleSlot = 1  -- Assuming cobblestone is in slot 1
    turtle.select(cobbleSlot)
    if placeFunc() then
        print("Placed cobblestone")
        return true
    else
        print("Failed to place cobblestone")
        return false
    end
end

-- Helper function to mine and collect loot
local function mineAndCollect()
    turtle.dig()
    turtle.suck()
end

-- Helper function to check and handle a block in a given direction
local function checkAndHandleBlock(inspectFunc, digFunc, placeFunc, direction)
    local success, data = inspectFunc()
    if success then
        print("Block " .. direction .. ": " .. data.name)
        if isFluid(data.name) then
            print("Replacing fluid " .. direction .. ": " .. data.name)
            placeCobble(placeFunc)
        elseif isValuableOre(data.name) then
            print("Mining valuable ore " .. direction .. ": " .. data.name)
            digFunc()
            turtle.suck()
        end
    else
        print("No block detected " .. direction .. " or unable to inspect")
    end
end

-- Helper function to return to the starting position
local function returnToStart(distance)
    -- Turn around
    turtle.turnRight()
    turtle.turnRight()
    
    -- Move back to the starting position
    for i = 1, distance do
        -- If blocked, try to dig and move
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suck()
            else
                print("Cannot move back. Blocked at position " .. (distance - i + 1))
                return false
            end
        end
        
        -- Check fuel and refuel if necessary
        if turtle.getFuelLevel() < 100 then
            refuelWithCoalOrCharcoal()
        end
    end
    
    -- Turn back to original orientation
    turtle.turnRight()
    turtle.turnRight()
    
    return true
end

-- Main bore function
function bore(distance)
    local actualDistance = 0
    for i = 1, distance do
        -- Check fuel level and refuel if needed
        if turtle.getFuelLevel() < 100 then
            if not refuelWithCoalOrCharcoal() then
                print("Out of fuel. Returning to start.")
                returnToStart(actualDistance)
                return false
            end
        end

        -- Check and handle block in front
        local success, data = turtle.inspect()
        if success then
            print("Block in front: " .. data.name)
            if isFluid(data.name) then
                placeCobble(turtle.place)
            end
            mineAndCollectWithFallingBlocks()
        end
        
        -- Move forward
        if turtle.forward() then
            actualDistance = actualDistance + 1
            print("Moved forward. Position: " .. actualDistance)
        else
            print("Cannot move forward. Obstacle at position " .. i)
            break
        end
        
        -- Check and handle block above
        checkAndHandleBlock(turtle.inspectUp, turtle.digUp, turtle.placeUp, "above")
        
        -- Check and handle block below
        checkAndHandleBlock(turtle.inspectDown, turtle.digDown, turtle.placeDown, "below")
        
        -- Check and handle block to the left
        turtle.turnLeft()
        checkAndHandleBlock(turtle.inspect, turtle.dig, turtle.place, "to the left")
        turtle.turnRight()
        
        -- Check and handle block to the right
        turtle.turnRight()
        checkAndHandleBlock(turtle.inspect, turtle.dig, turtle.place, "to the right")
        turtle.turnLeft()
    end
    
    print("Boring complete. Returning to start.")
    local returnSuccess = returnToStart(actualDistance)
    
    if returnSuccess then
        print("Returned to starting position successfully.")
        return true
    else
        print("Failed to return to starting position.")
        return false
    end
end

local success = bore(64)
if success then
    print("Bore operation completed successfully.")
else
    print("Bore operation encountered an issue.")
end