-- layered_mining.lua

-- Import the mining library and inventory management library
local lib_mining = require("/lib/lib_mining")
local lib_inv_mgmt = require("/lib/lib_inv_mgmt")

-- Constants
local MAIN_SHAFT_LENGTH = 64
local SIDE_SHAFT_INTERVAL = 5
local SIDE_SHAFT_LENGTH = 64
local TOTAL_LAYERS = 16

-- Starting X positions for each layer
local START_X_POSITIONS = {1, 3, 5, 2, 4}

-- Helper function to return from a side shaft
local function sideShaftReturn(length)
    -- Turn around
    turtle.turnRight()
    turtle.turnRight()
    
    -- Move back to the main shaft
    for i = 1, length do
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suck()
            else
                print("Cannot move back. Blocked at position " .. (length - i + 1))
                return false
            end
        end
        
        -- Check fuel level and refuel if needed
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                print("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    -- Turn to face the original direction
    turtle.turnRight()
    
    return true
end

-- Helper function to return to the starting position (0,0,0)
local function mainShaftReturn(x, y, z)
    -- Turn around
    turtle.turnRight()
    turtle.turnRight()
    
    -- Move back to x = 0
    for i = 1, x do
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suck()
            else
                print("Cannot move back. Blocked at position " .. (x - i + 1))
                return false
            end
        end
        
        -- Check fuel level and refuel if needed
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                print("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    -- Turn to face -y direction
    if y > 0 then
        turtle.turnRight()
    elseif y < 0 then
        turtle.turnLeft()
    end
    
    -- Move back to y = 0
    for i = 1, math.abs(y) do
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suck()
            else
                print("Cannot move back. Blocked at y position " .. (math.abs(y) - i + 1))
                return false
            end
        end
        
        -- Check fuel level and refuel if needed
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                print("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    -- Move down to z = 0
    for i = 1, z do
        while not turtle.down() do
            if turtle.digDown() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suckDown()
            else
                print("Cannot move down. Blocked at z position " .. (z - i + 1))
                return false
            end
        end
        
        -- Check fuel level and refuel if needed
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                print("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    -- Turn to face +x direction
    if y ~= 0 then
        turtle.turnLeft()
    end
    
    return true
end

-- Main mining function
local function layeredMining()
    for layer = 0, TOTAL_LAYERS - 1 do
        local startX = START_X_POSITIONS[(layer % 5) + 1]
        local startZ = layer
        
        print("Starting layer " .. layer .. " at X: " .. startX .. ", Z: " .. startZ)
        
        -- Move to start position
        for i = 1, startZ do
            turtle.up()
        end
        for i = 1, startX - 1 do
            turtle.forward()
        end
        
        -- Mine main shaft
        for x = startX, MAIN_SHAFT_LENGTH do
            -- Check fuel level and refuel if needed
            if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
                if not lib_mining.refuel() then
                    print("Low on fuel. Continuing, but may need to refuel soon.")
                end
            end
            
            -- Mine forward
            lib_mining.mineAndCollectWithFallingBlocks()
            turtle.forward()
            
            -- Check if we need to mine a side shaft
            if (x - startX) % SIDE_SHAFT_INTERVAL == 0 then
                turtle.turnLeft()
                
                -- Mine side shaft
                for y = 1, SIDE_SHAFT_LENGTH do
                    lib_mining.mineAndCollectWithFallingBlocks()
                    turtle.forward()
                    
                    -- Check and handle blocks in all directions
                    lib_mining.checkAndHandleBlock(turtle.inspectUp, turtle.placeUp, turtle.placeUp, turtle.digUp, "above")
                    lib_mining.checkAndHandleBlock(turtle.inspectDown, turtle.placeDown, turtle.placeDown, turtle.digDown, "below")
                    
                    turtle.turnLeft()
                    lib_mining.checkAndHandleBlock(turtle.inspect, turtle.place, turtle.place, turtle.dig, "to the left")
                    turtle.turnRight()
                    
                    turtle.turnRight()
                    lib_mining.checkAndHandleBlock(turtle.inspect, turtle.place, turtle.place, turtle.dig, "to the right")
                    turtle.turnLeft()
                    
                    -- Check fuel level and refuel if needed
                    if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
                        if not lib_mining.refuel() then
                            print("Low on fuel. Continuing, but may need to refuel soon.")
                        end
                    end
                end
                
                -- Return to main shaft
                if not sideShaftReturn(SIDE_SHAFT_LENGTH) then
                    print("Failed to return from side shaft. Aborting operation.")
                    return false
                end
                
                lib_inv_mgmt.dumpNonValuableItems()
            end
            
            -- Check and handle blocks in all directions
            lib_mining.checkAndHandleBlock(turtle.inspectUp, turtle.placeUp, turtle.placeUp, turtle.digUp, "above")
            lib_mining.checkAndHandleBlock(turtle.inspectDown, turtle.placeDown, turtle.placeDown, turtle.digDown, "below")
        end
        
        -- Return to start and deposit items
        if not mainShaftReturn(MAIN_SHAFT_LENGTH - startX + 1, 0, startZ) then
            print("Failed to return to start. Aborting operation.")
            return false
        end
        
        lib_inv_mgmt.depositItems()
        
        -- Check if we should abort due to low fuel after completing a layer
        if turtle.getFuelLevel() < 1000 then
            print("Fuel level critically low after completing a layer. Aborting operation.")
            return false
        end
    end
    
    return true
end

-- Run the layered mining operation
local success = layeredMining()
if success then
    print("Layered mining operation completed successfully.")
else
    print("Layered mining operation encountered an issue.")
end