-- layered_mining.lua

-- Import the required libraries
local lib_mining = require("/lib/lib_mining")
local lib_inv_mgmt = require("/lib/lib_inv_mgmt")
local lib_debug = require("/lib/lib_debug")

-- Parse command-line arguments
local args = {...}
local MAIN_SHAFT_LENGTH = 32
local SIDE_SHAFT_LENGTH = 32
local SIDE_SHAFT_INTERVAL = 5
local TOTAL_LAYERS = 16

for i = 1, #args do
    if args[i] == "-v" then
        lib_debug.set_verbose(true)
    elseif args[i] == "-m" and args[i+1] then
        MAIN_SHAFT_LENGTH = tonumber(args[i+1])
    elseif args[i] == "-s" and args[i+1] then
        SIDE_SHAFT_LENGTH = tonumber(args[i+1])
    elseif args[i] == "-i" and args[i+1] then
        SIDE_SHAFT_INTERVAL = tonumber(args[i+1])
    elseif args[i] == "-t" and args[i+1] then
        TOTAL_LAYERS = tonumber(args[i+1])
    end
end

-- Starting X positions for each layer
local START_X_POSITIONS = {1, 3, 5, 2, 4}

-- Helper function to move up safely
local function safeUp()
    while not turtle.up() do
        if turtle.digUp() then
            sleep(0.5)  -- Wait for blocks to fall
            turtle.suckUp()
        else
            lib_debug.print_debug("Cannot move up. Unbreakable block above.")
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
            lib_debug.print_debug("Cannot move forward. Unbreakable block in front.")
            return false
        end
    end
    return true
end

-- Helper function to return from a side shaft
local function sideShaftReturn(length)
    turtle.turnRight()
    turtle.turnRight()
    
    for i = 1, length do
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)
                turtle.suck()
            else
                lib_debug.print_debug("Cannot move back. Blocked at position " .. (length - i + 1))
                return false
            end
        end
        
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                lib_debug.print_debug("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    turtle.turnLeft()
    turtle.turnLeft()
    return true
end

-- Helper function to return to the starting position (0,0,0)
local function mainShaftReturn(length, height, startX)
    turtle.turnRight()
    turtle.turnRight()
    
    for i = 1, length + (startX - 1) do
        while not turtle.forward() do
            if turtle.dig() then
                sleep(0.5)
                turtle.suck()
            else
                lib_debug.print_debug("Cannot move back. Blocked at position " .. (length + startX - i))
                return false
            end
        end
        
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                lib_debug.print_debug("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    for i = 1, height do
        while not turtle.down() do
            if turtle.digDown() then
                sleep(0.5)
                turtle.suckDown()
            else
                lib_debug.print_debug("Cannot move down. Blocked at height " .. (height - i + 1))
                return false
            end
        end
        
        if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
            if not lib_mining.refuel() then
                lib_debug.print_debug("Low on fuel. Continuing, but may need to refuel soon.")
            end
        end
    end
    
    turtle.turnRight()
    turtle.turnRight()
    
    return true
end

-- Main mining function
local function layeredMining()
    for layer = 0, TOTAL_LAYERS - 1 do
        local startX = START_X_POSITIONS[(layer % 5) + 1]
        local startZ = layer
        
        lib_debug.print_debug("Starting layer " .. layer .. " at X: " .. startX .. ", Z: " .. startZ)
        
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
        
        for x = startX, MAIN_SHAFT_LENGTH do
            if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
                if not lib_mining.refuel() then
                    lib_debug.print_debug("Low on fuel. Continuing, but may need to refuel soon.")
                end
            end
            
            lib_mining.mineAndCollectWithFallingBlocks()
            if not safeForward() then
                print("Failed to move forward in main shaft. Aborting operation.")
                return false
            end
            
            if (x - startX) % SIDE_SHAFT_INTERVAL == 0 then
                turtle.turnLeft()
                
                for y = 1, SIDE_SHAFT_LENGTH do
                    lib_mining.mineAndCollectWithFallingBlocks()
                    if not safeForward() then
                        print("Failed to move forward in side shaft. Aborting operation.")
                        return false
                    end
                    
                    lib_mining.checkAndHandleBlock(turtle.inspectUp, turtle.placeUp, turtle.placeUp, turtle.digUp, "above")
                    lib_mining.checkAndHandleBlock(turtle.inspectDown, turtle.placeDown, turtle.placeDown, turtle.digDown, "below")
                    
                    turtle.turnLeft()
                    lib_mining.checkAndHandleBlock(turtle.inspect, turtle.place, turtle.place, turtle.dig, "to the left")
                    turtle.turnRight()
                    
                    turtle.turnRight()
                    lib_mining.checkAndHandleBlock(turtle.inspect, turtle.place, turtle.place, turtle.dig, "to the right")
                    turtle.turnLeft()
                    
                    if turtle.getFuelLevel() < turtle.getFuelLimit() - 1000 then
                        if not lib_mining.refuel() then
                            lib_debug.print_debug("Low on fuel. Continuing, but may need to refuel soon.")
                        end
                    end
                end
                
                if not sideShaftReturn(SIDE_SHAFT_LENGTH) then
                    print("Failed to return from side shaft. Aborting operation.")
                    return false
                end
                
                lib_inv_mgmt.dumpNonValuableItems()
                turtle.turnRight()
            end
        end
        
        if not mainShaftReturn(MAIN_SHAFT_LENGTH - startX + 1, startZ, startX) then
            print("Failed to return to start. Aborting operation.")
            return false
        end
        
        local hasChest, data = turtle.inspectDown()
        if hasChest and data.name:find("chest") then
            lib_inv_mgmt.depositItems()
        else
            print("No chest found below. Terminating program without dropping items.")
            return false
        end
        
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