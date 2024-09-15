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
            if(#list < #size) then
                return chest
            end
        end
    end
end

function storageLib.findEmptySlot(chest)
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
        chest, slot = storageLib.findEmptySlot()
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

function storageLib.getItems(item,count,destSlot)
    local dest = nil
    local itemList = {}
    if count == nil then
        count = 64
    end
    if turtle then
        dest = storageLib.getTurtleHandle()
    else
        dest = storageLib.localChest
    end 
    print("destination:",dest)
    if type(item) == "string" then
        itemList = {item}
    end
    local err = false
    for i=1,#itemList do
        ::continue::
        local chests = storageLib.findItemsInStash(itemList[i])
        local found = 0
        for chest, slots in pairs(chests) do
            print("Pulling from chest:"..chest)
            for _,s in ipairs(slots) do
                local c = peripheral.wrap(chest)
                local x = c.pushItems(dest,s,destSlot)
                found = found + x
                if found >= count then 
                    goto continue
                end
            end
        end
        if found < count then
            err = true
        end
    end
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


return storageLib