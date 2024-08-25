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

local function placeCobblestoneWalls()
    local cobblestoneSlot = findCobblestone()
    if not cobblestoneSlot then
        lib_debug.print_debug("No cobblestone found in inventory")
        return false
    end

    turtle.select(cobblestoneSlot)

    for _ = 1, 4 do
        local success, data = turtle.inspect()
        if not success or data.name == "minecraft:air" then
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

        -- Check fuel level
        if move.getFuelLevel() < 100 then
            lib_debug.print_debug("Low fuel, returning home")
            break
        end
    end

    -- Return home
    lib_debug.print_debug("Returning home")
    move.goHome()
end

-- Run the main function
pipeDown()