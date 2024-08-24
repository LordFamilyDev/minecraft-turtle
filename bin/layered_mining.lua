-- layered_mining.lua

-- Import the mining library and inventory management library
local lib_mining = require("/lib/lib_mining")
local lib_inv_mgmt = require("/lib/lib_inv_mgmt")

-- Constants
local MAIN_SHAFT_LENGTH = 32
local SIDE_SHAFT_INTERVAL = 5
local SIDE_SHAFT_LENGTH = 32
local TOTAL_LAYERS = 16

-- Starting X positions for each layer
local START_X_POSITIONS = {1, 3, 5, 2, 4}

-- Helper function to move up safely
local function safeUp()
    while not turtle.up() do
        if turtle.digUp() then
            sleep(0.5)  -- Wait for blocks to fall
            turtle.suckUp()
        else
            print("Cannot move up. Unbreakable block above.")
            return false
        end
    end
    return true
end

-- Helper function to move forward safely
local function safeForward()
    while not turtle.forward() do
        if turtle.dig() then
            sleep(0.5)  -- Wait for blocks to fall
            turtle.suck()
        else
            print("Cannot move forward. Unbreakable block in front.")
            return false
        end
    end
    return true
end

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
    turtle.turnLeft()
    turtle.turnLeft()
    return true
end

-- Helper function to return to the starting position (0,0,0)
local function mainShaftReturn(length, height, startX)
    -- Turn around
    turtle.turnRight()
    turtle.turnRight()
    
    -- Move back to x = 0, plus the offset
    for i = 1, length + (startX - 1) do
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suck()
            else
                print("Cannot move back. Blocked at position " .. (length + startX - i))
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
    for i = 1, height do
        while not turtle.down() do
            if turtle.digDown() then
                sleep(0.5)  -- Wait for blocks to drop
                turtle.suckDown()
            else
                print("Cannot move down. Blocked at height " .. (height - i + 1))
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
    turtle.turnRight()
    turtle.turnRight()
    
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
            if not safeUp() then
                print("Failed to move up to layer " .. layer .. ". Aborting operation.")
                return false
            end
        end
        for i = 1, startX - 1 do
            if not safeForward() then
                print("Failed to move to start X position. Aborting operation.")
                return false
            end
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
            if not safeForward() then
                print("Failed to move forward in main shaft. Aborting operation.")
                return false
            end
            
            -- Check if we need to mine a side shaft
            if (x - startX) % SIDE_SHAFT_INTERVAL == 0 then
                turtle.turnLeft()
                
                -- Mine side shaft
                for y = 1, SIDE_SHAFT_LENGTH do
                    lib_mining.mineAndCollectWithFallingBlocks()
                    if not safeForward() then
                        print("Failed to move forward in side shaft. Aborting operation.")
                        return false
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
                turtle.turnRight()
            end
        end
        
        -- Return to start and deposit items
        if not mainShaftReturn(MAIN_SHAFT_LENGTH - startX + 1, startZ, startX) then
            print("Failed to return to start. Aborting operation.")
            return false
        end
        
        -- Check for chest below before depositing items
        local hasChest, data = turtle.inspectDown()
        if hasChest and data.name:find("chest") then
            lib_inv_mgmt.depositItems()
        else
            print("No chest found below. Terminating program without dropping items.")
            return false
        end
        
        -- Check if we should abort due to low fuel after completing a layer
        if turtle.getFuelLevel() < 1000 then
            print("Fuel level critically low (below 1000) after completing a layer. Aborting operation.")
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