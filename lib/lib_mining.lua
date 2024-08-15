-- lib_mining.lua

local lib = {}

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
                    print("Refueled with lava bucket")
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
                    print("Refueled with " .. item.name)
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
    return blockName == "minecraft:iron_ore" or 
           blockName == "minecraft:diamond_ore" or 
           blockName == "minecraft:coal_ore" or
           blockName == "minecraft:deepslate_iron_ore" or
           blockName == "minecraft:deepslate_diamond_ore" or
           blockName == "minecraft:deepslate_coal_ore" or
           blockName == "minecraft:redstone_ore" or
           blockName == "minecraft:deepslate_redstone_ore" or
           blockName == "minecraft:gold_ore" or
           blockName == "minecraft:deepslate_gold_ore" or
           blockName == "minecraft:emerald_ore" or
           blockName == "minecraft:deepslate_emerald_ore" or
           blockName == "minecraft:lapis_ore" or
           blockName == "minecraft:deepslate_lapis_ore"
end

-- Helper function to place cobblestone
function lib.placeCobble(placeFunc)
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
        print("Block " .. direction .. ": " .. data.name)
        if data.name == "minecraft:lava" then
            local bucketSlot = lib.findEmptyBucket()
            if bucketSlot then
                turtle.select(bucketSlot)
                if collectFunc() then
                    print("Collected lava " .. direction)
                else
                    print("Failed to collect lava " .. direction)
                    lib.placeCobble(placeFunc)
                end
            else
                print("No empty bucket available to collect lava " .. direction)
                lib.placeCobble(placeFunc)
            end
        elseif data.name == "minecraft:water" then
            print("Replacing water " .. direction)
            lib.placeCobble(placeFunc)
        elseif lib.isValuableOre(data.name) then
            print("Mining valuable ore " .. direction .. ": " .. data.name)
            digFunc()
            turtle.suck()
        end
    else
        print("No block detected " .. direction .. " or unable to inspect")
    end
end

return lib