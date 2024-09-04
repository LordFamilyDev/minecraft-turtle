--layout:
--computer with wired modem on back
--cable to block modem (take default modem and craft it to make it a block) with chests around it
--have one chest near the computer that will be your clientChest (use the name given when turning on its modem when initializing system)
--bump Tom if this doesn't make sense and I will fix this explanation

local lib = {}

lib.userChest = nil
lib.storageChests = {}
lib.clientChestNameFile = "resources/clientChestName.txt"

--TODO: helper functions
function lib.getCount(blockName)
end

function lib.inventoryTimeTest()
    local startTime = os.clock()
    local chestSize = lib.storageChests[1].size()
    for slot = 1, chestSize do
        if lib.storageChests[1].getItemDetail(slot) then
            --do nothing
        end
    end
    print("test1: " .. os.clock() - startTime)

    startTime = os.clock()
    local items = lib.storageChests[1].list()
    for _ in pairs(items) do
        --do nothing
    end
    print("test2: " .. os.clock() - startTime)
end

function lib.getStorageUtilization()
    local totalStorage = 0
    local usedStorage = 0
    for i = 1, #lib.storageChests do
        local chestSize = lib.storageChests[i].size()
        totalStorage = totalStorage + chestSize
        local items = lib.storageChests[i].list()
        -- Count the number of filled slots
        for _ in pairs(items) do
            usedStorage = usedStorage + 1
        end
    end
    return usedStorage, totalStorage
end

--attempts to combine stacks
function lib.refineStorage()
end

-- Function to read client chest name from file
function lib.readClientChestName()
    if fs.exists(lib.clientChestNameFile) then
        local file = fs.open(lib.clientChestNameFile, "r")
        local name = file.readLine()
        file.close()
        return name
    else
        print("clientChestName.txt missing, run initialize with chest name to correct")
        return nil
    end
end

-- Function to write client chest name to file
function lib.writeClientChestName(name)
    -- Check if the resources directory exists, and create it if not
    if not fs.exists("resources") then
        fs.makeDir("resources")
    end

    local file = fs.open(lib.clientChestNameFile, "w")
    file.writeLine(name)
    file.close()
end

function lib.ensureMinecraftPrefix(itemName)
    local prefix = "minecraft:"

    -- Check if the itemName starts with "minecraft:"
    if string.sub(itemName, 1, string.len(prefix)) ~= prefix then
        -- If not, append the prefix to the itemName
        itemName = prefix .. itemName
    end

    return itemName
end

function lib.initializeStorage()
    --load clientChestName from file if it exists or return the file doesnt exist
    local savedClientChestName = lib.readClientChestName()
    if savedClientChestName == nil then
        return
    end

    -- Check if any chests were found
    local storageIndexCounter = 1
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "minecraft:chest" then
            --print(name)
            if name == savedClientChestName then
                lib.userChest = peripheral.wrap(name)
            elseif name == "left" or name == "right" or name == "top" or name == "bottom" then
                --do nothing, these chests are technically not connected to the cable network...
            else
                lib.storageChests[storageIndexCounter] = peripheral.wrap(name)
                storageIndexCounter = storageIndexCounter + 1
            end
        end
    end

    if storageIndexCounter == 1 then
        print("no chests found in network")
    end

    if lib.userChest == nil then
        print("user chest not found")
    end
end

function lib.transferMaterial(source, destination, partialBlockName, amount)

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
            if itemDetail and itemDetail.nbt and textutils.serialize(itemDetail.nbt):find(partialBlockName) then
                local transferred = source.pushItems(peripheral.getName(destination), slot,amount)
                return transferred
            end
        end
    end
    return 0
end

function lib.requestMaterial(partialBlockName, amount)
    local transferredCount = 0
    local chestIndex = 1
    while chestIndex <= #lib.storageChests do
        local transferred = transferMaterial(lib.storageChests[chestIndex],lib.userChest,partialBlockName,amount)
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

function lib.clearUserStorage()
    -- Iterate through all slots in the user chest
    for slot, item in pairs(lib.userChest.list()) do
        -- Try to move the item to one of the storage chests
        for _, storageChest in ipairs(lib.storageChests) do
            local transferred = lib.userChest.pushItems(peripheral.getName(storageChest), slot)
            
            -- If all items from the slot were transferred, move to the next slot
            if transferred == item.count then
                break
            elseif transferred then
                -- If some items remain, update the item count and try the next chest
                item.count = item.count - transferred
            end
        end
    end

    print("User chest cleared.")
end

--runs on module import
lib.initializeStorage()

return lib