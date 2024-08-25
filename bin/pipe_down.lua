local move = require("/lib/move")
local lib_debug = require("/lib/lib_debug")

local function findCobblestone()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:cobblestone" then
            return slot
        end
    end
    return nil
end

local function shouldPlaceCobblestone(blockName)
    return blockName == "minecraft:air" or 
           blockName == "minecraft:water" or 
           blockName == "minecraft:lava" or 
           blockName == "minecraft:flowing_water" or 
           blockName == "minecraft:flowing_lava"
end

local function placeCobblestoneWalls()
    local cobblestoneSlot = findCobblestone()
    if not cobblestoneSlot then
        lib_debug.print_debug("No cobblestone found in inventory")
        return false
    end

    turtle.select(cobblestoneSlot)

    for _ = 1, 4 do
        local success, data = turtle.inspect()
        if not success or shouldPlaceCobblestone(data.name) then
            if not turtle.place() then
                lib_debug.print_debug("Failed to place cobblestone")
                return false
            end
        end
        move.turnRight()
    end

    return true
end

local function pipeDown()
    while true do
        -- Check if we've hit bedrock
        local success, data = turtle.inspectDown()
        if success and data.name == "minecraft:bedrock" then
            lib_debug.print_debug("Bedrock detected, stopping descent")
            break
        end

        -- Check fuel and refuel if necessary
        if turtle.getFuelLevel() < 100 then
            if not move.refuel() then
                lib_debug.print_debug("Failed to refuel and fuel level low, returning home")
                break
            end
        end

        -- Dig down if there's a block
        if not move.goDown(true) then
            lib_debug.print_debug("Failed to move down, stopping descent")
            break
        end

        -- Place cobblestone walls
        if not placeCobblestoneWalls() then
            lib_debug.print_debug("Failed to place cobblestone walls, returning home")
            break
        end
    end

    -- Return home
    lib_debug.print_debug("Returning home")
    move.goHome()
end

-- Run the main function
pipeDown()