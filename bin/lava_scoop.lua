local move = require("/lib/move")
local lib_debug = require("/lib/lib_debug")

local function hasBucket()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and (item.name == "minecraft:bucket" or item.name == "minecraft:lava_bucket") then
            return true
        end
    end
    return false
end

local function findEmptyBucket()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:bucket" then
            return slot
        end
    end
    return nil
end

local function checkFuel()
    local fuelLevel = turtle.getFuelLevel()
    local fuelLimit = turtle.getFuelLimit()
    return fuelLevel > fuelLimit - 1000
end

local function scoopLava()
    for _ = 1, 4 do
        local success, data = turtle.inspect()
        if success and data.name == "minecraft:lava" then
            local bucketSlot = findEmptyBucket()
            if bucketSlot then
                turtle.select(bucketSlot)
                if turtle.place() then
                    lib_debug.print_debug("Collected lava in front")
                    if not move.refuel() then
                        lib_debug.print_debug("Failed to refuel with lava")
                    end
                else
                    lib_debug.print_debug("Failed to collect lava in front")
                end
            else
                lib_debug.print_debug("No empty bucket available to collect lava")
            end
        end
        move.turnRight()
    end
end

local function lavaScoop()
    if not hasBucket() then
        error("No bucket found in inventory")
    end

    if checkFuel() then
        print("Fuel level: " .. turtle.getFuelLevel())
        return
    end

    while true do
        scoopLava()  -- Check all horizontal directions

        if checkFuel() then
            print("Fuel level: " .. turtle.getFuelLevel())
            move.goHome()
            return
        end

        local success, data = turtle.inspectDown()
        if success then
            if data.name == "minecraft:lava" then
                local bucketSlot = findEmptyBucket()
                if bucketSlot then
                    turtle.select(bucketSlot)
                    if turtle.placeDown() then
                        lib_debug.print_debug("Collected lava below")
                        if not move.refuel() then
                            lib_debug.print_debug("Failed to refuel with lava")
                        end
                    else
                        lib_debug.print_debug("Failed to collect lava below")
                    end
                else
                    lib_debug.print_debug("No empty bucket available to collect lava")
                    break
                end
            elseif data.name ~= "minecraft:air" then
                lib_debug.print_debug("Solid block detected below, stopping descent")
                break
            end
        else
            lib_debug.print_debug("No block below (air), continuing descent")
        end

        if not move.goDown(true) then
            lib_debug.print_debug("Failed to move down, stopping descent")
            break
        end
    end
    move.goHome()
end

local function findLavaAndScoop(iterations)
    while not hasBucket() do
        print("Give me a bucket...")
        sleep(2)
    end
    move.setHome()

    for i = 1, iterations do
        -- Move forward until lava is detected underneath
        while true do
            local success, data = turtle.inspectDown()
            --lava state level 0 means source, but level 2 makes sure scooping happens ever step rather than every two due to forward scooping
            if success and data.name == "minecraft:lava" and data.state.level <= 2 then
                lib_debug.print_debug("Lava detected underneath, starting lava scoop operation")
                break
            end

            if not move.goForward(true) then
                lib_debug.print_debug("Path blocked, cannot continue forward")
                move.goHome()
                return
            end

            if move.distToHome()>30 then
                print("Lava search too far max dist 30")
                move.goHome()
                return
            end

            if checkFuel() then
                print("Fuel level too high: " .. turtle.getFuelLevel())
                move.goHome()
                return
            end
        end

        -- Start lava scooping operation
        lavaScoop()
        print("Fuel level: " .. turtle.getFuelLevel())
    end
end

function launch() 
    while not hasBucket() do
        print("Give me a bucket...")
        sleep(2)
    end
    move.refuel()
    move.goForward()
    move.goForward()
    move.goDown()
    move.setHome()
    if not iterations then
        iterations = 1
    end
    findLavaAndScoop(iterations)
    move.goUp()
    move.goUp()
    move.goBackwards()
    move.goBackwards()
end

-- Run the main function

-- Capture arguments passed to the script
local args = {...}

for i=1,#args,2 do
    if args[i] == "--launch" then 
        launch()
    elseif args[i] == "-i" then
        iterations = tonumber(args[i+1])
    end
end

if not iterations then
    iterations = 1
end

findLavaAndScoop(iterations)