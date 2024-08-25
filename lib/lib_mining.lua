-- lib_mining.lua

local lib = {}
local lib_debug = require("/lib/lib_debug")

-- Refuel function
function lib.refuel()
    local fuelLevel = turtle.getFuelLevel()
    local fuelLimit = turtle.getFuelLimit()

    -- Always try to use lava buckets first if not nearly full
    if fuelLevel < fuelLimit - 1000 then
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and item.name == "minecraft:lava_bucket" then
                turtle.select(slot)
                if turtle.refuel(1) then
                    lib_debug.print_debug("Refueled with lava bucket")
                    return true
                end
            end
        end
    end

    -- If still low on fuel, use coal or charcoal
    if fuelLevel < 1000 then
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and (item.name == "minecraft:coal" or item.name == "minecraft:charcoal") then
                turtle.select(slot)
                if turtle.refuel(1) then
                    lib_debug.print_debug("Refueled with " .. item.name)
                    return true
                end
            end
        end
    end

    -- If we got here, we couldn't refuel
    return false
end

-- Helper function to check if a block is lava or water
function lib.isFluid(blockName)
    return blockName == "minecraft:lava" or blockName == "minecraft:water"
end

-- Helper function to mine and collect loot, handling falling blocks
function lib.mineAndCollectWithFallingBlocks()
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
function lib.isValuableOre(blockName)
    local valuableOres = {
        -- Overworld ores
        "minecraft:iron_ore",
        "minecraft:diamond_ore",
        "minecraft:coal_ore",
        "minecraft:redstone_ore",
        "minecraft:gold_ore",
        "minecraft:emerald_ore",
        "minecraft:lapis_ore",
        -- Deepslate variants
        "minecraft:deepslate_iron_ore",
        "minecraft:deepslate_diamond_ore",
        "minecraft:deepslate_coal_ore",
        "minecraft:deepslate_redstone_ore",
        "minecraft:deepslate_gold_ore",
        "minecraft:deepslate_emerald_ore",
        "minecraft:deepslate_lapis_ore",
        -- Nether ores
        "minecraft:nether_quartz_ore",
        "minecraft:nether_gold_ore",
        "minecraft:ancient_debris"
    }

    for _, ore in ipairs(valuableOres) do
        if blockName == ore then
            return true
        end
    end

    return false
end

-- Helper function to place cobblestone
function lib.placeCobble(placeFunc)
    local cobbleSlot = 1  -- Assuming cobblestone is in slot 1
    turtle.select(cobbleSlot)
    if placeFunc() then
        lib_debug.print_debug("Placed cobblestone")
        return true
    else
        lib_debug.print_debug("Failed to place cobblestone")
        return false
    end
end

-- Helper function to find an empty bucket
function lib.findEmptyBucket()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:bucket" then
            return slot
        end
    end
    return nil
end

-- Helper function to check and handle a block in a given direction
function lib.checkAndHandleBlock(inspectFunc, collectFunc, placeFunc, digFunc, direction)
    local success, data = inspectFunc()
    if success then
        lib_debug.print_debug("Block " .. direction .. ": " .. data.name)
        if data.name == "minecraft:lava" then
            local bucketSlot = lib.findEmptyBucket()
            if bucketSlot then
                turtle.select(bucketSlot)
                if collectFunc() then
                    lib_debug.print_debug("Collected lava " .. direction)
                else
                    lib_debug.print_debug("Failed to collect lava " .. direction)
                    lib.placeCobble(placeFunc)
                end
            else
                lib_debug.print_debug("No empty bucket available to collect lava " .. direction)
                lib.placeCobble(placeFunc)
            end
        elseif data.name == "minecraft:water" then
            lib_debug.print_debug("Replacing water " .. direction)
            lib.placeCobble(placeFunc)
        elseif lib.isValuableOre(data.name) then
            lib_debug.print_debug("Mining valuable ore " .. direction .. ": " .. data.name)
            digFunc()
            turtle.suck()
        end
    else
        lib_debug.print_debug("No block detected " .. direction .. " or unable to inspect")
    end
end

return lib