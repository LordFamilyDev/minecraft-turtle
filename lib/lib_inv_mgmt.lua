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
function lib.depositItems(startIndex)
    if startIndex == nil then
        startIndex = 1
    end

    turtle.turnRight()
    turtle.turnRight()
    for slot = startIndex, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name ~= "minecraft:bucket" and item.name ~= "minecraft:lava_bucket" then
            turtle.select(slot)
            turtle.dropDown()
        end
    end
    turtle.turnRight()
    turtle.turnRight()
end

-- Function to deposit items in the chest in front
function lib.depositItems_Front(startIndex)
    if startIndex == nil then
        startIndex = 1
    end

    for slot = startIndex, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            turtle.select(slot)
            turtle.drop()
        end
    end
end

function lib.transferInventory(startIndex, direction, blockNames, dropFlag)
    -- Validate the startIndex
    if startIndex < 1 or startIndex > 16 then
        error("Invalid startIndex. It should be between 1 and 16.")
    end
    
    -- Validate the direction
    local validDirections = {up = true, down = true, front = true}
    if not validDirections[direction] then
        error("Invalid direction. It should be 'up', 'down', or 'front'.")
    end
    
    local transferSuccess = true
    
    -- Transfer specified blocks to the chest
    for i = startIndex, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            for _, blockName in ipairs(blockNames) do
                if item.name == blockName then
                    turtle.select(i)
                    local dropFunction = direction == "up" and turtle.dropUp or
                                         direction == "down" and turtle.dropDown or
                                         turtle.drop
                    if not dropFunction() then
                        transferSuccess = false
                    end
                    break
                end
            end
        end
    end
    
    -- Drop remaining items if dropFlag is true
    if dropFlag then
        for i = startIndex, 16 do
            local item = turtle.getItemDetail(i)
            if item then
                turtle.select(i)
                turtle.dropDown()
            end
        end
    end
    
    return transferSuccess
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

function lib.selectWithRefill(slot, startingSlot)
    if startingSlot == nil then
        startingSlot = slot
    end

    -- Select the slot to place from
    turtle.select(slot)

    -- Check how many items are in the selected slot
    local itemDetail = turtle.getItemDetail(slot)
    
    if not itemDetail then
        print("No item in selected slot.")
        return false
    end

    -- If there's only one item left, search for more in subsequent slots
    if turtle.getItemCount(slot) == 1 then
        local found = false
        for i = startingSlot + 1, 16 do
            local detail = turtle.getItemDetail(i)
            if detail and detail.name == itemDetail.name then
                -- Transfer items from the subsequent slot to the original slot
                turtle.select(i)
                turtle.transferTo(slot)
                found = true
                break
            end
        end

        -- If no additional items were found, return false
        if not found then
            turtle.select(slot)
            print("Unable to refill material: " .. turtle.getItemDetail(slot).name)
            return false
        end
    end

    turtle.select(slot)
    return true
end


return lib