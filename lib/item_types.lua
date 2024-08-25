
local lib = {}

lib.treeBlocks = {
-- Logs
"minecraft:oak_log",
"minecraft:spruce_log",
"minecraft:birch_log",
"minecraft:jungle_log",
"minecraft:acacia_log",
"minecraft:dark_oak_log",
"minecraft:mangrove_log",
"minecraft:cherry_log",
-- Leaves
"minecraft:oak_leaves",
"minecraft:spruce_leaves",
"minecraft:birch_leaves",
"minecraft:jungle_leaves",
"minecraft:acacia_leaves",
"minecraft:dark_oak_leaves",
"minecraft:mangrove_leaves",
"minecraft:cherry_leaves",
"minecraft:azalea_leaves",
"minecraft:flowering_azalea_leaves"
}

-- List of key minerals to look for
lib.keyMinerals = {
    "minecraft:diamond_ore",
    "minecraft:iron_ore",
    "minecraft:coal_ore",
    "minecraft:gold_ore",
    "minecraft:emerald_ore",
    "minecraft:lapis_ore",
    "minecraft:redstone_ore",
    "minecraft:deepslate_diamond_ore",
    "minecraft:deepslate_iron_ore",
    "minecraft:deepslate_coal_ore",
    "minecraft:deepslate_gold_ore",
    "minecraft:deepslate_emerald_ore",
    "minecraft:deepslate_lapis_ore",
    "minecraft:deepslate_redstone_ore"
}

-- Global list of unwanted items
lib.unwantedItems = {
    "minecraft:cobblestone",
    --"minecraft:granite",
    "minecraft:cobbled_deepslate"
}

--List of items not to mine (this list should be much longer, but im lazy)
lib.noMine = {
    "minecraft:chest",
    "minecraft:barrel",
    "minecraft:furnace"
}

function lib.isItemInList(itemInfo, list)
    for _, itemType in ipairs(list) do
        if itemInfo:find(itemType) then
            return true
        end
    end
    return false
end

-- Sry not sure if exactly the same as yours (idk how to overload in lua)
function lib.isBlockNameInList(blockName,list)
    for _, mineral in ipairs(list) do
        if blockName == mineral then
            return true
        end
    end
    return false
end

function lib.isTree(item)
    return lib.isItemInList(item, lib.treeBlocks)
end

function lib.isTreeFwd()
    x, info = turtle.inspect()
    return x and lib.isTree(info.name)
end 

function lib.isTreeUp()
    x, info = turtle.inspectUp()
    return x and lib.isTree(info.name)
end

function lib.isTreeDown()
    x, info = turtle.inspectUp()
    return x and lib.isTree(info.name)
end

return lib