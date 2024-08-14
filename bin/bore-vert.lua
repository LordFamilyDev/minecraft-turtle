-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
--
-- SPDX-License-Identifier: LicenseRef-CCPL

-- boring vertical shafts
-- basic code pulled from the excavate program in the ComputerCraft examples

if not turtle then
    printError("Requires a Turtle")
    return
end

local maxDepth = 0
local numBores = 1
local startBore = 0

local tArgs = { ... }
if #tArgs >= 1 then
    startBore = tonumber(tArgs[1])
end
if #tArgs >= 2 then
    numBores = tonumber(tArgs[2])
end
if #tArgs >= 3 then
    maxDepth = tonumber(tArgs[3])
end



-- Mine in a quarry pattern until we hit something we can't dig
-- local size = tonumber(tArgs[1])
-- if size < 1 then
--     print("Excavate diameter must be positive")
--     return
-- end

local size = 1

local depth = 0
local unloaded = 0
local collected = 0

local xPos, zPos = 0, 0
local xDir, zDir = 0, 1

local goTo -- Filled in further down
local refuel -- Filled in further down

local function unload(_bKeepOneFuelStack)
    print("Unloading items...")
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount > 0 then
            turtle.select(n)
            local bDrop = true
            if _bKeepOneFuelStack and turtle.refuel(0) then
                bDrop = false
                _bKeepOneFuelStack = false
            end
            if bDrop then
                turtle.drop()
                unloaded = unloaded + nCount
            end
        end
    end
    collected = 0
    turtle.select(1)
end

local function returnSupplies()
    local x, y, z, xd, zd = xPos, depth, zPos, xDir, zDir
    print("Returning to surface...")
    goTo(0, 0, 0, 0, -1, false)

    local fuelNeeded = 2 * (x + y + z) + 1
    if not refuel(fuelNeeded) then
        unload(true)
        print("Waiting for fuel")
        while not refuel(fuelNeeded) do
            os.pullEvent("turtle_inventory")
        end
    else
        unload(true)
    end

    print("Resuming mining...")
    goTo(x, y, z, xd, zd, false)
end

local function collect()
    local bFull = true
    local nTotalItems = 0
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount == 0 then
            bFull = false
        end
        nTotalItems = nTotalItems + nCount
    end

    if nTotalItems > collected then
        collected = nTotalItems
        if math.fmod(collected + unloaded, 50) == 0 then
            print("Mined " .. collected + unloaded .. " items.")
        end
    end

    if bFull then
        print("No empty slots left.")
        return false
    end
    return true
end

local function scanAndSuck()
	local block, data = turtle.inspect()
    local ignoreBlock = false
    if block then
        if data.name == "minecraft:stone" then
            ignoreBlock = true
        end
        if not ignoreBlock then
            if turtle.dig() then
                turtle.suck()
                collect()
            end
        end
    end
end

local function sitAndSpin()
    for i = 1, 4 do
        scanAndSuck()
        turtle.turnRight()
    end
end

function findItem(name, select)
    for n = 1, 16 do
        local item = turtle.getItemDetail(n)
        if item and item.name == name then
            if select then
                turtle.select(n)
            end
            return n
        end
    end
    return nil
end

function refuel(amount)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then
        return true
    end

    local needed = amount or xPos + zPos + depth + 2
    if turtle.getFuelLevel() < needed then
        for n = 1, 16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                if turtle.refuel(1) then
                    while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
                        turtle.refuel(1)
                    end
                    if turtle.getFuelLevel() >= needed then
                        turtle.select(1)
                        return true
                    end
                end
            end
        end
        turtle.select(1)
        return false
    end

    return true
end

local function tryForwards()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.forward() do
        if turtle.detect() then
            if turtle.dig() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attack() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end

    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end

local function tryDown()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.down() do
        if turtle.detectDown() then
            if turtle.digDown() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attackDown() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end

    depth = depth + 1
    if math.fmod(depth, 10) == 0 then
        print("Descended " .. depth .. " metres.")
    end

    return true
end

local function turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end

local function turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end

function goTo(x, y, z, xd, zd, fill)
    while depth > y do
        if turtle.up() then
            depth = depth - 1
            fillMod = math.fmod(depth, 10)
            if fill  and fillMod then
                if findItem("minecraft:cobblestone", true) then
                    turtle.placeDown()
                end
            end
        elseif turtle.digUp() or turtle.attackUp() then
            collect()
        else
            sleep(0.5)
        end
    end

    if xPos > x then
        while xDir ~= -1 do
            turnLeft()
        end
        while xPos > x do
            if turtle.forward() then
                xPos = xPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif xPos < x then
        while xDir ~= 1 do
            turnLeft()
        end
        while xPos < x do
            if turtle.forward() then
                xPos = xPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end

    if zPos > z then
        while zDir ~= -1 do
            turnLeft()
        end
        while zPos > z do
            if turtle.forward() then
                zPos = zPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif zPos < z then
        while zDir ~= 1 do
            turnLeft()
        end
        while zPos < z do
            if turtle.forward() then
                zPos = zPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end

    while depth < y do
        if turtle.down() then
            depth = depth + 1
        elseif turtle.digDown() or turtle.attackDown() then
            collect()
        else
            sleep(0.5)
        end
    end

    while zDir ~= zd or xDir ~= xd do
        turnLeft()
    end
end

if not refuel() then
    print("Out of Fuel")
    return
end

local function startBore()
    tryDown()
    for i = 1, 4 do
        turtle.dig()
        findItem("minecraft:cobblestone", true)
        turtle.place()
        turtle.turnRight()
    end
    tryDown()
end

local function bore()
    startBore()
    local done = false
    while not done do
        sitAndSpin()
        if not tryDown() then
            print("Nothing below me")
            done = true
            break
        end
        if maxDepth > 0 and depth > maxDepth then
            print("Reached max depth of " .. maxDepth)
            done = true
            break
        end
    end
    print("Returning to surface...")  
end

local boreX = 0 
local boreZ = 0

local function findNextBore()
    boreX = boreX + 2
    boreZ = boreZ + 1
    goTo(boreX, 0, boreZ, 0, 1, true)
end


-- Main loop
for i = 1 , startBore - 1 do
    findNextBore()
end

print("Excavating...")

turtle.select(1)
local boreCount = 0
while boreCount < numBores do
    boreCount = boreCount + 1
    print("Bore #" .. boreCount)
    bore()
    goTo(xPos, 0, zPos, xDir, zDir, true)
    c = findItem("minecraft:cobblestone", true)
    if c then
        turtle.select(c)
        turtle.placeDown()
    end
    goTo(0, 0, 0, 0, -1, false)
    unload(true)
    if boreCount < numBores then
        findNextBore()
end

-- Return to where we started
goTo(0, 0, 0, 0, -1, true)
unload(false)
goTo(0, 0, 0, 0, 1, false)

print("Mined " .. collected + unloaded .. " items total.")
print("Dug " .. boreCount .. " bores.")