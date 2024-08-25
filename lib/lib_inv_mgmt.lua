-- lib_inv_mgmt.lua

local lib = {}

-- List of valuable items to keep
lib.valuableItems = {
    "minecraft:diamond",
    "minecraft:emerald",
    "minecraft:gold_ingot",
    "minecraft:iron_ingot",
    "minecraft:coal",
    "minecraft:redstone",
    "minecraft:lapis_lazuli",
    "minecraft:gold_nugget",
    "minecraft:raw_gold",
    "minecraft:raw_iron",
    "minecraft:ancient_debris",
    "minecraft:quartz",
    "minecraft:flint",
}

-- Helper function to check if an item is valuable
function lib.isValuableItem(itemName)
    for _, valuable in ipairs(lib.valuableItems) do
        if itemName == valuable then
            return true
        end
    end
    return false
end

-- Function to dump non-valuable items
function lib.dumpNonValuableItems()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and not lib.isValuableItem(item.name) and item.name ~= "minecraft:bucket" and item.name ~= "minecraft:lava_bucket" then
            turtle.select(slot)
            turtle.drop()
        end
    end
end

-- Function to deposit items in the chest below
function lib.depositItems()
    turtle.turnRight()
    turtle.turnRight()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name ~= "minecraft:bucket" and item.name ~= "minecraft:lava_bucket" then
            turtle.select(slot)
            turtle.dropDown()
        end
    end
    turtle.turnRight()
    turtle.turnRight()
end

return lib