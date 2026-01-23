-- Assuming storage and move libraries are already required
local storage = require("/lib/storage")
local move = require("/lib/move")
local farmLib = require("/lib/farming")
local lib_inv_mgmt = require("/lib/lib_inv_mgmt")

local function attemptFarmFlint()
    local GRAVEL_SLOT = 1

    while true do
        -- Pull a stack of gravel from storage
        storage.getItems("minecraft:gravel", 64, GRAVEL_SLOT, true)
        turtle.select(GRAVEL_SLOT)


        if turtle.getItemCount(GRAVEL_SLOT) == 0 then
            print("No gravel available in storage.")
            return false
        end

        local flintCount = 0
        local continue = true

        turtle.select(GRAVEL_SLOT)

        -- Place and dig gravel until we run out or collect 64 flint
        while continue do
            if flintCount == 64 then
                storage.pushItem(2,64)
                flintCount = 0
                turtle.select(GRAVEL_SLOT)
            end

            -- Place gravel forward
            turtle.place()
            turtle.dig()
            sleep(0.1)
            local slot = turtle.getItemDetail(GRAVEL_SLOT)
            if slot == nil or slot.name == "minecraft:flint" then
                continue = false
            end
        end
        -- Push all items back to storage
        storage.pushItem("all")
    end
    return true
end

local function buildSticks()
    turtle.select(1)
    storage.getItems("minecraft:spruce_log", 8, 1, true)
    local success = turtle.craft()
    if success then
        turtle.transferTo(5,16)
    end
    success = turtle.craft()
    return success
end

local function buildArrows()
    while true do
        if buildSticks() then
            turtle.select(1)
            turtle.transferTo(5)
            storage.getItems("minecraft:flint",64,1,true)
            storage.getItems("minecraft:feather",64,9,true)
            local success = turtle.craft()
            if not success then
                print("failed to craft Arrow")
                storage.pushItem("all")
                return
            end
            storage.pushItem("all")
        else
            print("No more sticks")
            storage.pushItem("all")
            return
        end
    end
end

       

local function farmFlint()
    print("Starting Flint Farm")
    while true do
        local success = attemptFarmFlint()
        print("Out of gravel trying again in 1 minute")
        sleep(60)
    end
end


local function farmArrows()
    print("Starting Arrow Builder")
    -- while true do
        buildArrows()
    -- sleep(60)
    -- end
end

local function farmObsidian()
    -- Check if we have a bucket
    local slot = storage.findItemsInTurtle("bucket", 1)
    if not slot then
        print("No bucket found in storage. Cannot farm obsidian.")
        return
    end
    turtle.select(slot[1])
    turtle.transferTo(1)
    turtle.select(1)
    -- Find the Cauldron
    while true do
        local found, data = turtle.inspect()
        if found and data.name == "minecraft:cauldron" or data.name == "minecraft:lava_cauldron" then
            break
        end
        move.turnLeft()
        sleep(0.5)
    end
       
    -- Start farming obsidian
    while true do
        local success, data = turtle.inspect()
        if success and data.name == "minecraft:lava_cauldron" then
            -- Collect lava
            turtle.place()
            move.turnLeft()
            move.turnLeft()
            turtle.place()
            sleep(1)
            -- Dig obsidian
            turtle.dig()
            move.turnLeft()
            move.turnLeft()
        else
            print("No lava cauldron found, waiting 5 seconds before retrying.")
            sleep(5)
        end
        sleep(0.5)
    end
end

local function farmWheat(row, col)
    while true do
        local SEED_SLOT = 1
        move.setHome()
        move.goForward(false)
        local dir = 0
        for c = 1, col do
            for r = 1, row do
                if farmLib.isFullyGrownWheatBelow() then
                    turtle.digDown()
                    lib_inv_mgmt.selectWithRefill(1,5)
                    turtle.placeDown()
                end
                move.goForward(false)
            end
            if dir == 0 then
                move.turnRight()
                move.goForward(false)
                move.turnRight()
                dir = 1
            else
                move.turnLeft()
                move.goForward(false)
                move.turnLeft()
                dir = 0
            end
        end
        move.pathTo(1,0,0)
        move.turnTo(1,0)
        move.goBackwards(false)

        sleep(10*60)
    end
end

function buildPaper()
    local sugarcaneCount = 0
    -- First pass: push paper down and count sugarcane
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        
        if item then
            if item.name == "minecraft:paper" then
                -- Push paper to chest below
                turtle.dropDown()
            elseif item.name == "minecraft:sugar" then -- whoops added sugar by mistake
                -- Push sugar to chest below
                turtle.dropDown()
            elseif item.name == "minecraft:sugar_cane" then
                sugarcaneCount = sugarcaneCount + item.count
                if slot > 1 then
                    if not turtle.transferTo(1, item.count) then
                        if not turtle.transferTo(2, item.count) then
                            if not turtle.transferTo(3, item.count) then
                                turtle.dropDown()
                            end
                        end
                    end
                end
            end
        end
    end

    if sugarcaneCount < 3 then
        return
    end

    -- Evenly distribute sugarcane into first three slots
    local perSlot = math.floor(sugarcaneCount / 3)
    for slot = 1, 2 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        local currentCount = item and item.count or 0
        if currentCount > perSlot then
            turtle.transferTo(slot + 1, currentCount - perSlot)
        end
    end
    turtle.select(1)

    -- Craft paper
    turtle.craft()

end


local function farmSugarCane()
    while true do
        turtle.dig()
        buildPaper()
        move.turnRight()
        sleep(0.5)
    end
end

local args = {...}

-- Function to parse arguments
local function parseArgs()
    for i = 1, #args do
        if args[i] == "flint" then
            print("Farming Flint")
            farmFlint()
            return
        elseif args[i] == "arrow" then
            print("Farming Arrows")
            farmArrows()
            return            
        elseif args[i] == "obsidian" then
            print("Farming Obsidian")
            farmObsidian()
            return            
        elseif args[i] == "wheat" then
            local row = args[i+1]
            local col = args[i+2]
            print("Farming Wheat")
            farmWheat(row, col)
            return
        elseif args[i] == "sugarcane" then
            print("Farming Sugar Cane")
            farmSugarCane()
            return
        end
    end
    print("Not Supported")
end

-- Parse command-line arguments
parseArgs()