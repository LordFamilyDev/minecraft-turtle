-- lib_inv.lua
-- Inventory Management Library for ComputerCraft Turtles

local lib_inv = {}

-- Helper function to find and activate the wired modem
local function activateWiredModem()
    local sides = {"top", "bottom", "front", "back", "left", "right"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" and not peripheral.call(side, "isWireless") then
            print("Found wired modem on " .. side)
            rednet.open(side)
            return peripheral.wrap(side), peripheral.call(side, "getNameLocal")
        end
    end
    print("No wired modem found")
    return nil, nil
end

-- Helper function to get chest names
local function getChestNames()
    local names = peripheral.getNames()
    local chests = {}
    for _, name in ipairs(names) do
        if peripheral.getType(name) == "minecraft:chest" then
            table.insert(chests, name)
        end
    end
    print("Found " .. #chests .. " chests")
    return chests
end

-- Helper function to find an item in chests
local function findItemInChests(itemName)
    local chests = getChestNames()
    for _, chestName in ipairs(chests) do
        print("Checking chest: " .. chestName)
        local chest = peripheral.wrap(chestName)
        if not chest then
            print("Failed to wrap chest: " .. chestName)
        else
            local items = chest.list()
            if not items then
                print("Failed to list items in chest: " .. chestName)
            else
                for slot, item in pairs(items) do
                    if item.name == itemName then
                        print("Found " .. itemName .. " in " .. chestName .. " at slot " .. slot)
                        return chestName, slot
                    end
                end
            end
        end
    end
    print("Item not found: " .. itemName)
    return nil, nil
end

-- Helper function to find a free slot in chests
local function findFreeSlotInChests()
    local chests = getChestNames()
    for _, chestName in ipairs(chests) do
        print("Checking for free slot in chest: " .. chestName)
        local chest = peripheral.wrap(chestName)
        if not chest then
            print("Failed to wrap chest: " .. chestName)
        else
            local items = chest.list()
            if not items then
                print("Failed to list items in chest: " .. chestName)
            else
                for slot = 1, chest.size() do
                    if not items[slot] then
                        print("Found free slot in " .. chestName .. " at slot " .. slot)
                        return chestName, slot
                    end
                end
            end
        end
    end
    print("No free slots found in any chest")
    return nil, nil
end

-- Helper function to safely get item count
local function safeGetItemCount(chest, slot)
    local detail = chest.getItemDetail(slot)
    return detail and detail.count or 0
end

-- Function to get items from chests to turtle's inventory
function lib_inv.get(item, count)
    local modem, turtleName = activateWiredModem()
    if not modem or not turtleName then
        error("Failed to activate wired modem or get turtle name")
    end

    print("Attempting to get " .. count .. " of " .. item)

    local remaining = count
    while remaining > 0 do
        local chestName, slot = findItemInChests(item)
        if not chestName then
            rednet.close()
            error("Item not found: " .. item)
        end

        local chest = peripheral.wrap(chestName)
        if not chest then
            rednet.close()
            error("Failed to wrap chest: " .. chestName)
        end

        local items = chest.list()
        if not items then
            rednet.close()
            error("Failed to list items in chest: " .. chestName)
        end

        print("Chest contents:")
        for slot, item in pairs(items) do
            print(slot .. ": " .. item.name .. " x" .. item.count)
        end

        local transferred = chest.pushItems(turtleName, slot, remaining)
        if transferred == 0 then
            rednet.close()
            error("Failed to transfer items from slot " .. slot)
        end
        remaining = remaining - transferred
        print("Transferred " .. transferred .. " items, " .. remaining .. " remaining")
    end

    rednet.close()
end

-- Function to put items from turtle's inventory to chests
function lib_inv.put(item, count)
    local modem, turtleName = activateWiredModem()
    if not modem or not turtleName then
        error("Failed to activate wired modem or get turtle name")
    end

    print("Attempting to put " .. count .. " of " .. item)

    local remaining = count
    while remaining > 0 do
        local chestName, slot = findFreeSlotInChests()
        if not chestName then
            rednet.close()
            error("No free slots in chests")
        end

        local chest = peripheral.wrap(chestName)
        if not chest then
            rednet.close()
            error("Failed to wrap chest: " .. chestName)
        end

        local transferred = 0
        for i = 1, 16 do
            local itemDetail = turtle.getItemDetail(i)
            if itemDetail and itemDetail.name == item then
                transferred = chest.pullItems(turtleName, i, remaining)
                break
            end
        end
        if transferred == 0 then
            rednet.close()
            error("Failed to transfer items")
        end
        remaining = remaining - transferred
        print("Transferred " .. transferred .. " items, " .. remaining .. " remaining")
    end

    rednet.close()
end

-- Function to find items matching a partial name
function lib_inv.find(item_partial)
    local modem, turtleName = activateWiredModem()
    if not modem or not turtleName then
        error("Failed to activate wired modem or get turtle name")
    end

    print("Searching for items matching: " .. item_partial)

    local matches = {}
    local chests = getChestNames()
    for _, chestName in ipairs(chests) do
        local chest = peripheral.wrap(chestName)
        if not chest then
            print("Failed to wrap chest: " .. chestName)
        else
            local items = chest.list()
            if not items then
                print("Failed to list items in chest: " .. chestName)
            else
                for slot, item in pairs(items) do
                    if item.name:find(item_partial) then
                        table.insert(matches, item.name)
                        print("Found match: " .. item.name .. " in " .. chestName)
                    end
                end
            end
        end
    end

    rednet.close()
    return matches
end

-- Function to merge stacks in turtle's inventory
function lib_inv.merge()
    print("Merging stacks in turtle's inventory")
    local inventory = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if not inventory[item.name] then
                inventory[item.name] = {slot = slot, count = item.count}
            else
                local targetSlot = inventory[item.name].slot
                local currentCount = turtle.getItemCount(slot)
                turtle.select(slot)
                turtle.transferTo(targetSlot)
                local newCount = turtle.getItemCount(slot)
                local transferred = currentCount - newCount
                if transferred > 0 then
                    inventory[item.name].count = inventory[item.name].count + transferred
                    if newCount > 0 then
                        inventory[item.name] = {slot = slot, count = newCount}
                    end
                    print("Merged " .. transferred .. " items of " .. item.name)
                end
            end
        end
    end
    turtle.select(1)
    print("Merge complete")
end

-- Function to merge stacks in remote chests
function lib_inv.mergeRemote()
    local modem, turtleName = activateWiredModem()
    if not modem or not turtleName then
        error("Failed to activate wired modem or get turtle name")
    end

    print("Merging stacks in remote chests")

    local chests = getChestNames()
    local inventory = {}

    -- First pass: build inventory of all items
    for _, chestName in ipairs(chests) do
        local chest = peripheral.wrap(chestName)
        if not chest then
            print("Failed to wrap chest: " .. chestName)
        else
            local items = chest.list()
            if not items then
                print("Failed to list items in chest: " .. chestName)
            else
                for slot, item in pairs(items) do
                    if not inventory[item.name] then
                        inventory[item.name] = {{chest = chestName, slot = slot, count = item.count}}
                    else
                        table.insert(inventory[item.name], {chest = chestName, slot = slot, count = item.count})
                    end
                end
            end
        end
    end

    -- Second pass: merge items
    for itemName, itemLocations in pairs(inventory) do
        local targetIndex = 1
        while #itemLocations > 1 and targetIndex < #itemLocations do
            local targetLocation = itemLocations[targetIndex]
            local targetChest = peripheral.wrap(targetLocation.chest)

            local sourceIndex = targetIndex + 1
            while sourceIndex <= #itemLocations do
                local sourceLocation = itemLocations[sourceIndex]
                if not sourceLocation then
                    print("Warning: Nil source location encountered for item " .. itemName)
                    break
                end

                local sourceChest = peripheral.wrap(sourceLocation.chest)
                
                local beforeCount = safeGetItemCount(targetChest, targetLocation.slot)
                targetChest.pullItems(sourceLocation.chest, sourceLocation.slot, 64, targetLocation.slot)
                local afterCount = safeGetItemCount(targetChest, targetLocation.slot)
                local transferred = afterCount - beforeCount
                
                if transferred > 0 then
                    targetLocation.count = afterCount
                    sourceLocation.count = sourceLocation.count - transferred
                    print("Merged " .. transferred .. " items of " .. itemName)

                    -- If source location is empty, remove it from the list
                    if sourceLocation.count <= 0 then
                        table.remove(itemLocations, sourceIndex)
                    else
                        sourceIndex = sourceIndex + 1
                    end

                    -- If target slot is full or close to full, move to the next target
                    if targetLocation.count >= 63 then
                        targetIndex = targetIndex + 1
                        break
                    end
                else
                    -- If no items were transferred, move to the next source
                    sourceIndex = sourceIndex + 1
                end
            end

            -- If we've processed all sources, move to the next target
            if sourceIndex > #itemLocations then
                targetIndex = targetIndex + 1
            end
        end
    end

    rednet.close()
    print("Remote merge complete")
end

return lib_inv