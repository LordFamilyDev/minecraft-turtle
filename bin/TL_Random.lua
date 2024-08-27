local lib_mining = require("/lib/lib_mining")
local lib_itemTypes = require("/lib/item_types")
local lib_move = require("/lib/move")
local lib_farming = require("/lib/farming")

function transferMaterial(source, destination, blockName, amount)
    -- Wrap the source and destination chests
    --local source = peripheral.wrap(fromChest)
    --local destination = peripheral.wrap(toChest)

    -- Iterate through all slots in the source chest
    for slot, item in pairs(source.list()) do
        -- Check if the item is stone
        if item.name == blockName then
            -- Attempt to transfer the stone to the destination chest
            local transferred = source.pushItems(peripheral.getName(destination), slot,amount)
            return transferred
        end
    end
    return 0
end

function requestMaterial(blockName, amount, userChest, storageChests)
    local transferredCount = 0
    for i = 1, #storageChests do
        local transferred = transferMaterial(storageChests[i],userChest,blockName,amount)
        transferredCount = transferredCount - transferred
        if transferredCount >= amount then
            return true
        end
    end
    return false
end

function clearUserStorage(userChest, storageChests)
    -- Iterate through all slots in the user chest
    for slot, item in pairs(userChest.list()) do
        -- Try to move the item to one of the storage chests
        for _, storageChest in ipairs(storageChests) do
            local transferred = userChest.pushItems(peripheral.getName(storageChest), slot)
            
            -- If all items from the slot were transferred, move to the next slot
            if transferred == item.count then
                break
            else
                -- If some items remain, update the item count and try the next chest
                item.count = item.count - transferred
            end
        end
    end

    print("User chest cleared.")
end

function inspectDownToPrint()
    local success, data = turtle.inspectDown()

    if success then
        for key, value in pairs(data) do
            print(key .. ": " .. tostring(value))
        end

        -- If `data.state` exists and is a table, you can print its contents as well
        if data.state then
            print("State:")
            for key, value in pairs(data.state) do
                print("  " .. key .. ": " .. tostring(value))
            end
        end
    else
        print("No block detected.")
    end
end

-- Capture arguments passed to the script
local args = {...}

local arg1 = tonumber(args[1])

-- Check if all arguments were provided and are valid integers
if arg1 then
    if arg1 == 1 then
        while true do
            lib_move.macroMove("FRFRFRFR",false,true)
        end
    elseif arg1 == 2 then
        while true do
            lib_move.macroMove("UFDRRFRR",false,true)
        end
    elseif arg1 == 3 then
        turtle.up()
        lib_farming.sweepUp(4)
        turtle.down()
    elseif arg1 == 4 then
        lib_move.goForward(true)
        inspectDownToPrint()
    elseif arg1 == 5 then
        local userChest = peripheral.wrap("minecraft:chest_6")
        local storageChests = {peripheral.wrap("minecraft:chest_7"),
        peripheral.wrap("minecraft:chest_8"),
        peripheral.wrap("minecraft:chest_9"),
        peripheral.wrap("minecraft:chest_10")}

        requestMaterial(args[2], 32, userChest, storageChests)
    elseif arg1 == 6 then
        local userChest = peripheral.wrap("minecraft:chest_6")
        local storageChests = {peripheral.wrap("minecraft:chest_7"),
        peripheral.wrap("minecraft:chest_8"),
        peripheral.wrap("minecraft:chest_9"),
        peripheral.wrap("minecraft:chest_10")}

        clearUserStorage(userChest, storageChests)
    end
    
else
    print("Please provide valid arguments:")
    print("1: horizontal move loop test")
    print("2: vertical move loop test")
    print("3: spiral sweep test")
    print("4: print block below")
    print("5: print block below")
end