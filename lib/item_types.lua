
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

function lib.isItemInList(itemInfo, list)
    for _, itemType in ipairs(list) do
        if itemInfo:find(itemType) then
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