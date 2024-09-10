itemTypes = require("/lib/item_types")
utils = require("/lib/utils")

storageLib = {}

local localChest = ""



function storageLib.setLocalChest( chestStr )
    localChest = chestStr
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
        if type == "minecraft:chest" then
            table.insert(chestList,pStr[i])
        end
    end
    return chestList
end

function storageLib.findEmptySlot()
    local chests = storageLib.getChestList()
    for i=1,#chests do 
        if chests[i] ~= localChest then
            local chest = peripheral.wrap(chests[i])
            local size = chest.size()
            for slot = 1,size do
                local item = chest.getItemDetail(slot)
                if item == nil then
                    return chests[i], slot
                end
            end
        end
    end
end

function storageLib.findItemInStash(item)
    local chests = storageLib.getChestList()
    for i=1,#chests do 
        if chests[i] ~= localChest then
            local chest = peripheral.wrap(chests[i])
            local size = chest.size()
            for slot = 1,size do
                local x = chest.getItemDetail(slot)
                if x  ~= nil and x.name:find(item) then
                    return chests[i], slot
                end
            end
        end
    end
end



function storageLib.getLocationListLocal(item)
    local list = {}
    if type(item) == "string" then
        if item == "all" then
            list = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
        else 
            if turtle then
                for slot = 1,16 do
                    local x = turtle.getItemDetail(slot)
                    if x ~= nil and x.name:find(item) then
                        table.insert(list,slot)
                    end
                end
            else
                --TODO: check if local chest set and then work from local chest            
            end
        end
    elseif type(item) == "table" then
        if turtle then
            for slot = 1, 16 do
                local x = turtle.getItemDetail(slot)
                if x then
                    if itemTypes.isItemInList(x.name, item) then
                        table.insert(list,slot)
                    end
                end
            end
        end
    elseif type(item) == "number" then
        list = {item}
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
        source = localChest
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

function storageLib.getItem(item,count,destSlot)
    local dest = nil
    local itemList = {}
    if count == nil then
        count = 64
    end
    if turtle then
        dest = storageLib.getTurtleHandle()
    else
        dest = localChest
    end 
    if type(item) == "string" then
        table.insert(itemList, item)
    end
    local err = false
    for i=1,#itemList do
        local found = 0
        while found < count do
            local chest, slot = storageLib.findItemInStash(itemList[i])
            if chest == nil then
                err = true
                break
            end
            c = peripheral.wrap(chest)
            local x = c.pushItems(dest,slot,destSlot)
            found = found + x
        end
    end
    return not err
end

return storageLib