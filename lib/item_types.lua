
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

-- List of all Minecraft sapling types
lib.saplingTypes = {
    "minecraft:oak_sapling",
    "minecraft:spruce_sapling",
    "minecraft:birch_sapling",
    "minecraft:jungle_sapling",
    "minecraft:acacia_sapling",
    "minecraft:dark_oak_sapling",
    "minecraft:mangrove_propagule",  -- Note: Technically a propagule, but functions as a sapling
    "minecraft:cherry_sapling",
    "minecraft:azalea",              -- Note: Functions as a sapling for azalea trees
    "minecraft:flowering_azalea"     -- Note: Can also grow into an azalea tree
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
    "minecraft:deepslate_redstone_ore",
    "minecraft:nether_quartz_ore",
    "minecraft:nether_gold_ore",
    "minecraft:ancient_debris",
    "minecraft:glowstone"
}

lib.valuableOres = {
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
    "minecraft:ancient_debris",
    "minecraft:glowstone",
    "minecraft:glowstone_dust"
}

-- Global list of unwanted items
lib.unwantedItems = {
    "minecraft:cobblestone",
    --"minecraft:granite",
    "minecraft:cobbled_deepslate",
    "minecraft:netherrack",
    "minecraft:blackstone",
    "minecraft:magma_block"
}

--List of items not to mine (this list should be much longer, but im lazy)
lib.noMine = {
    "minecraft:chest",
    "minecraft:barrel",
    "minecraft:furnace",
    "bed",
    "torch"
}

function lib.isItemInList(blockName, list)
    for _, str in ipairs(list) do
        if blockName:find(str) then
            return true
        end
    end
    return false
end

function lib.selectItem(itemToFind)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name ==  itemToFind then
            turtle.select(slot)
            return turtle.getItemCount()
        end
    end
    return false
end

function lib.selectItemFromList(list)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if lib.isItemInList(item.name, list) then
                turtle.select(slot)
                return turtle.getItemCount()
            end
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
    return x and lib.isTree(info.name), info.name
end 

function lib.isTreeUp()
    x, info = turtle.inspectUp()
    return x and lib.isTree(info.name)
end

function lib.isTreeDown()
    x, info = turtle.inspectUp()
    return x and lib.isTree(info.name)
end

function lib.getWood()
    return lib.selectItemFromList(lib.treeBlocks)
end

function lib.isSapling(item)
    return lib.isItemInList(item, lib.saplingTypes)
end

function lib.selectSapling()
    return lib.selectItemFromList(lib.saplingTypes)
end

return lib