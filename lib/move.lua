
local lib = {}

lib.depth = 0
lib.xPos,lib.zPos = 0,0
lib.xDir,lib.zDir = 1,0


function lib.distToHome()
    return math.abs(lib.xPos) + math.abs(lib.zPos) + lib.depth
end

function lib.faceDir(x, z)
    while x ~= lib.xDir or z ~= lib.zDir do
        turnRight()
    end
end

function lib.getDir()
    return lib.xDir, lib.zDir
end

function lib.getPos()
    return lib.xPos, lib.zPos
end

function lib.getdepth()
    return lib.depth
end

function lib.refuel()
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


function lib.dumpTrash()
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


function lib.turnLeft()
    turtle.turnLeft()
    lib.xDir, lib.zDir = lib.zDir, -lib.xDir
end

function lib.turnRight()
    turtle.turnRight()
    lib.xDir, lib.zDir = -lib.zDir, lib.xDir
end

function lib.goFroward(dig)
    if turtle.forward() then
        lib.xPos = lib.xPos + lib.xDir
        lib.zPos = lib.zPos + lib.zDir
        return true
    elseif dig and turtle.dig() then
        return turtle.forward()
    end
    return false
end

function lib.goUp(dig)
    if turtle.up() then
        lib.depth = lib.depth - 1
        return true
    elseif dig and turtle.digUp() then
        if turtle.up() then
            lib.depth = lib.depth - 1
            return true
        end
    end
    return false
end

function lib.goDown(dig)
    if turtle.down() then
        lib.depth = lib.depth + 1
        return true
    elseif dig and turtle.digDown() then
        if turtle.down() then
            lib.depth = lib.depth + 1
            return true
        end
    end
    return false
end

return lib