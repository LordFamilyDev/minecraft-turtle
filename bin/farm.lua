-- Assuming storage and move libraries are already required
local storage = require("/lib/storage")
local move = require("/lib/move")

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
    while true do
        if turtle.detect() then
            turtle.dig()
        end
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
        end
    end
    print("Not Supported")
end

-- Parse command-line arguments
parseArgs()