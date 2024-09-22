itemTypes = require("/lib/item_types")
utils = require("/lib/utils")
debug = require("/lib/lib_debug")

storageLib = {}

-- Configuration file name
local configFileName = "storage_config.json"

-- Initialize the configuration
local config = utils.readConfig(configFileName)

storageLib.localChest = config.localChest

-- Function to set the local chest
function storageLib.setLocalChest(chestStr)
    -- Update the local variable
    storageLib.localChest = chestStr
    
    -- Update the configuration
    config.localChest = chestStr
    
    -- Save the updated configuration
    utils.saveConfig(configFileName, config)
    
    print("Local chest set to: " .. chestStr)
end

function storageLib.getTurtleHandle()
    local modem = nil
    pStr = peripheral.getNames()
    for i = 1, #pStr do
        local type = peripheral.getType(pStr[i])
        if type == "modem" then
            modem = peripheral.wrap(pStr[i])
            return modem.getNameLocal()
        end
    end
    return nil
end

function storageLib.getChestList()
    local chestList = {}
    pStr = peripheral.getNames()
    for i = 1, #pStr do
        local type, ptype = peripheral.getType(pStr[i])
        if type == "minecraft:chest" and pStr[i]:find("minecraft") then
            table.insert(chestList,pStr[i])
        end
    end
    return chestList
end

function storageLib.findEmptyChest()
    local chests = storageLib.getChestList()
    for i=1,#chests do 
        if chests[i] ~= storageLib.localChest then
            local chest = peripheral.wrap(chests[i])
            local size = chest.size()
            local list = chest.list()
            if(#list < size) then
                return chests[i]
            end
        end
    end
end

function storageLib.findEmptySlot(chest)
    local chest = peripheral.wrap(chests[i])
    list = chest.list()
    for i=1,chest.size() do
        if list[i] == nil then
            return i
        end
    end
end


function storageLib.findItemsInChest(chest, item)
    local slots = {}
    local list = chest.list()
    if not list then return {} end
    for slot, val in pairs(list) do
        if type(item) == "string" then
            if val.name:find(item) then
                table.insert(slots,slot)
            end
        elseif type(item) == "table" then
            if itemTypes.isItemInList(val.name, item) then
                table.insert(slots,slot)
                print("adding slot"..slot)
            end
        end
    end
    return slots
end

function storageLib.findItemsInTurtle(item)
    local slots = {}
    for slot = 1,16 do
        local x = turtle.getItemDetail(slot)
        if type(item) == "string" then
            if x ~= nil and x.name:find(item) then
                table.insert(slots,slot)
            end
        elseif type(item) == "table" then
            if itemTypes.isItemInList(x.name, item) then
                table.insert(slots,slot)
            end
        end

    end
    return slots
end


function storageLib.findItemsInStash(item)
    local list = {}
    local chests = storageLib.getChestList()
    for i=1,#chests do 
        if chests[i] ~= storageLib.localChest then
            local chest = peripheral.wrap(chests[i])
            local slots = storageLib.findItemsInChest(chest,item)
            if #slots > 0 then
                list[chests[i]] = slots
            end
        end
    end
    return list
end




function storageLib.getLocationListLocal(item)
    local list = {}
    if type(item) == "number" then
        list = {item}
    elseif item == nil or (type(item) == "string" and item == "all") then
        if turtle then
            list = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
        elseif storageLib.localChest then
            local chest = peripheral.wrap(storageLib.localChest)
            for i = 1, chest.size() do
                table.insert(list, i)
            end
        end
    else 
        if turtle then
            list = storageLib.findItemsInTurtle(item)
        elseif storageLib.localChest then
                list = storageLib.findItemsInChest(peripheral.wrap(storageLib.localChest),item)
        end
    end
    return list
end

function storageLib.pushItem(item, count)
    local list = storageLib.getLocationListLocal(item)
    local source = nil
    if count == nil then
        count = 64
    end

    if turtle then
        source = storageLib.getTurtleHandle()
    else
        source = storageLib.localChest
    end 

    for i = 1, #list do
        chest = storageLib.findEmptyChest()
        -- slot = storageLib.findEmptySlot()
        if chest ~= nil then
            c = peripheral.wrap(chest)
            local x = c.pullItems(source, list[i], count)
            print("Pulled items:",x)
        else
            print("Failed to find an empty chest")
            return false
        end
    end
end

function storageLib.getItems(item, count, destSlot)
    local dest = nil
    local itemList = {}
    local found = 0  -- Keep track of how many items we've found

    -- Default count is 64 if not provided
    if count == nil then
        count = 64
    end

    -- Determine if the destination is a turtle or local chest
    if turtle then
        dest = storageLib.getTurtleHandle()
    else
        dest = storageLib.localChest
    end
    print("destination:", dest)

    -- Ensure itemList is a table
    if type(item) == "string" then
        itemList = {item}
    end

    local err = false

    -- Check the destination slot to update the `found` count
    local itemDetail = turtle.getItemDetail(destSlot)
    if itemDetail and itemDetail.name == item then
        -- Update found based on what's already in the destination slot
        found = itemDetail.count
        print("Slot " .. destSlot .. " already has " .. found .. " " .. item .. "(s)")
        if found >= count then
            print("Already have enough items in the slot.")
            return true -- We already have enough items in the slot, no need to pull more
        end
    elseif itemDetail and itemDetail.name ~= item then
        -- If the slot contains a different item, drop it
        print("Slot " .. destSlot .. " contains " .. itemDetail.name .. ", dropping it.")
        turtle.select(destSlot)
        turtle.drop()  -- Drop the incorrect item
    end

    -- Search for items in chests to pull into the destination slot
    for i = 1, #itemList do
        ::continue::
        local chests = storageLib.findItemsInStash(itemList[i])
        for chest, slots in pairs(chests) do
            print("Pulling from chest: " .. chest)
            for _, s in ipairs(slots) do
                local c = peripheral.wrap(chest)
                -- Pull the remaining needed items
                local toPull = count - found
                local pulled = c.pushItems(dest, s, toPull, destSlot)
                if pulled then
                    found = found + pulled
                end
                if found >= count then
                    --goto continue -- We've found enough items, skip to the next iteration
                    break
                end
            end
        end

        -- If we don't have enough items after searching all chests, mark an error
        if found < count then
            err = true
        end
    end

    -- Return success (true) or failure (false) based on whether we found enough items
    return not err
end



-- Helper function to print with pausing
local function printWithPause(lines)
    local lineCount = 0
    for _, line in ipairs(lines) do
        print(line)
        lineCount = lineCount + 1
        if lineCount % 15 == 0 then
            print("Press Enter to continue...")
            read()
        end
    end
end

function storageLib.getInventorySummary()
    local summary = {}
    local chestList = storageLib.getChestList()
    
    for _, chestName in ipairs(chestList) do
        local chest = peripheral.wrap(chestName)
        if chest then
            local items = chest.list()
            if items then
                for _, item in pairs(items) do
                    if summary[item.name] then
                        summary[item.name] = summary[item.name] + item.count
                    else
                        summary[item.name] = item.count
                    end
                end
            end
        else
            print("Warning: Unable to access chest " .. chestName)
        end
    end
    
    return summary
end

function storageLib.printInventorySummary()
    local summary = storageLib.getInventorySummary()
    if next(summary) then
        local lines = {"Inventory Summary (All Chests):"}
        for itemName, count in pairs(summary) do
            table.insert(lines, string.format("  %s: %d", itemName, count))
        end
        printWithPause(lines)
    else
        print("No items found in any chests.")
    end
end

function storageLib.getChestSummary(chestName)
    local summary = {}
    local chest = peripheral.wrap(chestName)
    
    if chest then
        local items = chest.list()
        for _, item in pairs(items) do
            if summary[item.name] then
                summary[item.name] = summary[item.name] + item.count
            else
                summary[item.name] = item.count
            end
        end
    else
        print("Error: Unable to access chest " .. chestName)
        return nil
    end
    
    return summary
end

function storageLib.printChestSummary(chestName)
    local summary = storageLib.getChestSummary(chestName)
    if summary and next(summary) then
        local lines = {string.format("Inventory Summary for %s:", chestName)}
        for itemName, count in pairs(summary) do
            table.insert(lines, string.format("  %s: %d", itemName, count))
        end
        printWithPause(lines)
    else
        print("No items found in the chest or chest not accessible.")
    end
end

function storageLib.craftWithPattern(itemGrid, itemNames, outputDirection)

    -- Step 1: Pull the required items for each crafting slot
    for slot = 1, 9 do
        local patternIndex = slot
        patternIndex = patternIndex + math.floor((slot - 1) / 3)
        local itemIndex = itemGrid[slot]
        if itemIndex and itemIndex > 0 then
            local blockName = itemNames[itemIndex]
            local result = storageLib.getItems(blockName,64,patternIndex)
            if not result then
                print("waiting for more mats")
                return false
            end
        end
    end

    -- Step 2: Craft the items (turtle's inventory should now match the 3x3 crafting grid)
    if turtle.craft() then
        print("Successfully crafted items.")
    else
        print("Crafting failed. Check if items are in the correct slots.")
        return false
    end

    -- Step 3: Deposit the crafted items into the output chest using turtle.drop()
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.getItemDetail(slot) then
            -- Move the turtle to drop the items into the output chest
            if outputDirection == "front" then
                turtle.drop()
            elseif outputDirection == "up" then
                turtle.dropUp()
            elseif outputDirection == "down" then
                turtle.dropDown()
            end
        end
    end

    -- Reset turtle selection
    turtle.select(1)
    return true
end

function storageLib.trash(itemName, dropDirection)
    local breakFlag = false
    while true do
        turtle.select(16)
        if dropDirection == "front" then
            turtle.drop()
        elseif dropDirection == "up" then
            turtle.dropUp()
        elseif dropDirection == "down" then
            turtle.dropDown()
        end
        if breakFlag then
            break
        end
        breakFlag = not storageLib.getItems(itemName, 64, 16)
    end
end

return storageLib