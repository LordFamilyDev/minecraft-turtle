local move = {}

local move.depth = 0
local move.xPos,move.zPos = 0,0
local move.xDir,move.zDir = 1,0


local function move.distToHome()
    return math.abs(move.xPos) + math.abs(move.zPos) + move.depth
end

local function move.faceDir(x, z)
    while x ~= move.xDir or z ~= move.zDir do
        turnRight()
    end
end

local function move.getDir()
    return move.xDir, move.zDir
end

local function move.getPos()
    return move.xPos, move.zPos
end

local function move.getdepth()
    return move.depth
end

local function move.refuel()
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


local function move.dumpTrash()
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


local function move.turnLeft()
    turtle.turnLeft()
    move.xDir, move.zDir = move.zDir, -move.xDir
end

local function move.turnRight()
    turtle.turnRight()
    move.xDir, move.zDir = -move.zDir, move.xDir
end

local function move.goFoward(dig)
    if turtle.forward() then
        move.xPos = move.xPos + move.xDir
        move.zPos = move.zPos + move.zDir
        return true
    elseif dig and turtle.dig() then
        return turtle.forward()
    end
    return false
end

local function move.goUp(dig)
    if turtle.up() then
        move.depth = move.depth - 1
        return true
    elseif dig and turtle.digUp() then
        if turtle.up() then
            move.depth = move.depth - 1
            return true
        end
    end
    return false
end

local function move.goDown(dig)
    if turtle.down() then
        move.depth = move.depth + 1
        return true
    elseif dig and turtle.digDown() then
        if turtle.down() then
            move.depth = move.depth + 1
            return true
        end
    end
    return false
end

return move