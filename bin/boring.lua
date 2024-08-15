-- boring.lua

-- Import the mining library
local lib_mining = require("/lib/lib_mining")

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
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            lib_mining.refuel()
        end
    end
    
    -- Turn back to original orientation
    turtle.turnRight()
    turtle.turnRight()
    
    return true
end

-- Main bore function
local function bore(distance)
    local actualDistance = 0
    for i = 1, distance do
        -- Check fuel level and refuel if needed
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                print("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end

        -- Check and handle block in front
        local success, data = turtle.inspect()
        if success then
            print("Block in front: " .. data.name)
            if data.name == "minecraft:lava" then
                local bucketSlot = lib_mining.findEmptyBucket()
                if bucketSlot then
                    turtle.select(bucketSlot)
                    if turtle.place() then
                        print("Collected lava in front")
                        -- Immediately try to use the lava for fuel if needed
                        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
                            turtle.refuel(1)
                            print("Refueled with collected lava")
                        end
                    else
                        print("Failed to collect lava in front")
                        lib_mining.placeCobble(turtle.place)
                    end
                else
                    print("No empty bucket available to collect lava in front")
                    lib_mining.placeCobble(turtle.place)
                end
            elseif data.name == "minecraft:water" then
                lib_mining.placeCobble(turtle.place)
            else
                lib_mining.mineAndCollectWithFallingBlocks()
            end
        end
        
        -- Move forward
        if turtle.forward() then
            actualDistance = actualDistance + 1
            print("Moved forward. Position: " .. actualDistance)
        else
            print("Cannot move forward. Obstacle at position " .. i)
            break
        end
        
        -- Check and handle blocks in all directions
        lib_mining.checkAndHandleBlock(turtle.inspectUp, turtle.placeUp, turtle.placeUp, turtle.digUp, "above")
        lib_mining.checkAndHandleBlock(turtle.inspectDown, turtle.placeDown, turtle.placeDown, turtle.digDown, "below")
        
        turtle.turnLeft()
        lib_mining.checkAndHandleBlock(turtle.inspect, turtle.place, turtle.place, turtle.dig, "to the left")
        turtle.turnRight()
        
        turtle.turnRight()
        lib_mining.checkAndHandleBlock(turtle.inspect, turtle.place, turtle.place, turtle.dig, "to the right")
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