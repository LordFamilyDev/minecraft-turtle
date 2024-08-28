--layout:
--computer with wired modem on back
--cable to block modem (take default modem and craft it to make it a block) with chests around it
--have one chest near the computer that will be your clientChest (use the name given when turning on its modem when initializing system)
--bump Tom if this doesn't make sense and I will fix this explanation


local userChest
local storageChests = {}
local clientChestNameFile = "resources/clientChestName.txt"

--TODO: helper functions
function getCount(blockName)
end

function countOpenSlots()
end

function refineStorage()
end

-- Function to read client chest name from file
function readClientChestName()
    if fs.exists(clientChestNameFile) then
        local file = fs.open(clientChestNameFile, "r")
        local name = file.readLine()
        file.close()
        return name
    else
        print("clientChestName.txt missing")
        return nil
    end
end

-- Function to write client chest name to file
function writeClientChestName(name)
    -- Check if the resources directory exists, and create it if not
    if not fs.exists("resources") then
        fs.makeDir("resources")
    end

    local file = fs.open(clientChestNameFile, "w")
    file.writeLine(name)
    file.close()
end

function ensureMinecraftPrefix(itemName)
    local prefix = "minecraft:"

    -- Check if the itemName starts with "minecraft:"
    if string.sub(itemName, 1, string.len(prefix)) ~= prefix then
        -- If not, append the prefix to the itemName
        itemName = prefix .. itemName
    end

    return itemName
end

function initializeStorage()
    --load clientChestName from file if it exists or return the file doesnt exist
    local savedClientChestName = readClientChestName()
    if savedClientChestName == nil then
        return
    end

    -- Check if any chests were found
    local storageIndexCounter = 1
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "minecraft:chest" then
            --print(name)
            if name == savedClientChestName then
                userChest = peripheral.wrap(name)
            elseif name == "left" or name == "right" or name == "top" or name == "bottom" then
                --do nothing, these chests are technically not connected to the cable network...
            else
                storageChests[storageIndexCounter] = peripheral.wrap(name)
                storageIndexCounter = storageIndexCounter + 1
            end
        end
    end

    if storageIndexCounter == 1 then
        print("no chests found in network")
    end

    if userChest == nil then
        print("user chest not found")
    end
end

function transferMaterial(source, destination, partialBlockName, amount)

    -- Iterate through all slots in the source chest
    --print(source.list())
    for slot, item in pairs(source.list()) do
        -- Check if the item is stone
        --if item.name == blockName then
        if item.name:find(partialBlockName) then
            -- Attempt to transfer the stone to the destination chest
            local transferred = source.pushItems(peripheral.getName(destination), slot,amount)
            return transferred
        elseif item.name:find("book") or item.name:find("potion") then
            local itemDetail = source.getItemDetail(slot)
            if itemDetail and textutils.serialize(itemDetail):find(partialBlockName) then
                local transferred = source.pushItems(peripheral.getName(destination), slot,amount)
                return transferred
            end
        end
    end
    return 0
end

function requestMaterial(partialBlockName, amount)
    local transferredCount = 0
    local chestIndex = 1
    while chestIndex <= #storageChests do
        local transferred = transferMaterial(storageChests[chestIndex],userChest,partialBlockName,amount)
        transferredCount = transferredCount + transferred
        if transferredCount >= amount then
            print(transferredCount .. " found")
            return true
        elseif transferred == 0 then
            chestIndex = chestIndex + 1
        else
            --I think this gives the chest a chance to update slots, calling too fast on same chest seems to break it
            sleep(0.01)
        end
    end
    print(transferredCount .. " found")
    return false
end

function clearUserStorage()
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

-- Capture arguments passed to the script
local args = {...}

initializeStorage()

if args[1] == nil or args[1] == "help" then
    print("usage:")
    print("get [partial or complete blockName] [quantity]")
    print("clear")
    print("initialize [clientChestName]")
elseif args[1] == "get" then
    if userChest == nil then
        print("initialize storage system before using")
    end
    if args[3] == nil then
        args[3] = 1
    end
    requestMaterial(args[2], tonumber(args[3]))
elseif args[1] == "clear" then
    if userChest == nil then
        print("initialize storage system before using")
    end
    clearUserStorage()
elseif args[1] == "initialize" then
    --verify that args[2] is a chest in the network and save it to file locally
    writeClientChestName(args[2])
end