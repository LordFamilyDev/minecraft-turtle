local move = require("/lib/move")
local lib_debug = require("/lib/lib_debug")

local function findCobbleSlab()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:cobblestone_slab" then
            return slot
        end
    end
    return nil
end

local function shouldPlaceSlab(blockName)
    return blockName == "minecraft:air" or 
           blockName == "minecraft:water" or 
           blockName == "minecraft:lava" or 
           blockName == "minecraft:flowing_water" or 
           blockName == "minecraft:flowing_lava"
end

local function placeSlabWalls()
    local slabSlot = findCobbleSlab()
    if not slabSlot then
        lib_debug.print_debug("No cobblestone slab found in inventory")
        return false
    end

    turtle.select(slabSlot)

    for _ = 1, 4 do
        local success, data = turtle.inspect()
        if not success or shouldPlaceSlab(data.name) then
            if not turtle.place() then
                lib_debug.print_debug("Failed to place cobblestone slab")
                return false
            end
        end
        move.turnRight()
    end

    return true
end

local function constructPipe(direction)
    local moveFunc = direction == "up" and move.goUp or move.goDown
    local inspectFunc = direction == "up" and turtle.inspectUp or turtle.inspectDown
    local maxDepth = direction == "up" and 319 or -64  -- Minecraft world limits

    while true do
        -- Check if we've hit bedrock or world limit
        local success, data = inspectFunc()
        if success and (data.name == "minecraft:bedrock" or move.getdepth() == maxDepth) then
            lib_debug.print_debug(direction == "up" and "World height limit reached" or "Bedrock detected, stopping")
            break
        end

        -- Check fuel and refuel if necessary
        if turtle.getFuelLevel() < 100 then
            if not move.refuel() then
                lib_debug.print_debug("Failed to refuel and fuel level low, returning home")
                break
            end
        end

        -- Move in the specified direction, digging if needed
        if not moveFunc(true) then
            lib_debug.print_debug("Failed to move " .. direction .. ", stopping construction")
            break
        end

        -- Place cobblestone slab walls
        if not placeSlabWalls() then
            lib_debug.print_debug("Failed to place cobblestone slab walls, returning home")
            break
        end
    end

    -- Return home
    lib_debug.print_debug("Returning home")
    move.goHome()
end

-- Parse command line arguments
local args = {...}
local direction
if args[1] == "up" then
    direction = "up"
else
    direction = "down"
end

-- Run the main function
constructPipe(direction)