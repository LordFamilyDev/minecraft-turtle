local depth = 0
local xPos,zPos = 0,0
local xDir,zDir = 1,0


function distToHome()
    return math.abs(xPos) + math.abs(zPos) + depth
end

function faceDir(x, z)
    while x ~= xDir or z ~= zDir do
        turnRight()
    end
end

function getDir()
    return xDir, zDir
end

function getPos()
    return xPos, zPos
end

function getDepth()
    return depth
end

function refuel()
    local fuelLevel = turtle.getFuelLevel()
    local fuelLimit = turtle.getFuelLimit()

    if fuelLevel == "unlimited" then
        return true
    end

    if fuelLevel > fuelLimit - 1000 then
        return true
    end

    -- Always try to use lava buckets first if not nearly full
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:lava_bucket" then
            turtle.select(slot)
            if turtle.refuel() then
                print("Refueled with lava bucket")
                return true
            end
        end
    end

    -- If still low on fuel, use coal or charcoal
    if fuelLevel < 1000 then
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and (item.name == "minecraft:coal" or item.name == "minecraft:charcoal") then
                turtle.select(slot)
                if turtle.refuel() then
                    print("Refueled with " .. item.name)
                    return true
                end
            end
        end
    end

    -- Burn it all
    for n = 1, 16 do
        turtle.select(n)
        if turtle.refuel() then
            return true
        end
    end

    turtle.select(1)

    -- If we got here, we couldn't refuel
    return false
end


function dumpTrash()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            if (item.name == "minecraft:cobblestone" 
                or item.name == "minecraft:dirt" 
                or item.name == "minecraft:gravel" 
                or item.name == "minecraft:cobbled_deepslate" ) then
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end


function turnLeft()
    turtle.turnLeft()
    xDir, zDir = zDir, -xDir
end

function turnRight()
    turtle.turnRight()
    xDir, zDir = -zDir, xDir
end

function goFoward(dig)
    if turtle.forward() then
        xPos = xPos + xDir
        zPos = zPos + zDir
        return true
    elseif dig and turtle.dig() then
        return turtle.forward()
    end
    return false
end

function goUp(dig)
    if turtle.up() then
        depth = depth - 1
        return true
    elseif dig and turtle.digUp() then
        if turtle.up() then
            depth = depth - 1
            return true
        end
    end
    return false
end

function goDown(dig)
    if turtle.down() then
        depth = depth + 1
        return true
    elseif dig and turtle.digDown() then
        if turtle.down() then
            depth = depth + 1
            return true
        end
    end
    return false
end