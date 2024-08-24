
local lib = {}

if _G.relativePosition == nil then
    _G.relativePosition = {}
    _G.relativePosition.depth = 0
    _G.relativePosition.xPos = 0
    _G.relativePosition.zPos = 0
    _G.relativePosition.xDir = 1
    _G.relativePosition.zDir = 0
end



function lib.setHome()
    _G.relativePosition.depth = 0
    _G.relativePosition.xPos = 0
    _G.relativePosition.zPos = 0
    _G.relativePosition.xDir = 1
    _G.relativePosition.zDir = 0
end

function lib.distToHome()
    return math.abs(_G.relativePosition.xPos) + math.abs(_G.relativePosition.zPos) + math.abs(_G.relativePosition.depth)
end

function lib.faceDir(x, z)
    while x ~= _G.relativePosition.xDir or z ~= _G.relativePosition.zDir do
        turnRight()
    end
end

function lib.getDir()
    return _G.relativePosition.xDir, _G.relativePosition.zDir
end

function lib.getPos()
    return _G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth
end

function lib.getdepth()
    return _G.relativePosition.depth
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
    _G.relativePosition.xDir, _G.relativePosition.zDir = _G.relativePosition.zDir, -_G.relativePosition.xDir
end

function lib.turnRight()
    turtle.turnRight()
    _G.relativePosition.xDir, _G.relativePosition.zDir = -_G.relativePosition.zDir, _G.relativePosition.xDir
end

function lib.goForward(dig)
    if turtle.forward() then
        _G.relativePosition.xPos = _G.relativePosition.xPos + _G.relativePosition.xDir
        _G.relativePosition.zPos = _G.relativePosition.zPos + _G.relativePosition.zDir
        return true
    elseif dig and turtle.dig() then
        if turtle.forward() then
            _G.relativePosition.xPos = _G.relativePosition.xPos + _G.relativePosition.xDir
            _G.relativePosition.zPos = _G.relativePosition.zPos + _G.relativePosition.zDir
            return true
        end
    end
    return false
end

function lib.goUp(dig)
    if turtle.up() then
        _G.relativePosition.depth = _G.relativePosition.depth + 1
        return true
    elseif dig and turtle.digUp() then
        if turtle.up() then
            _G.relativePosition.depth = _G.relativePosition.depth + 1
            return true
        end
    end
    return false
end

function lib.goDown(dig)
    if turtle.down() then
        _G.relativePosition.depth = _G.relativePosition.depth - 1
        return true
    elseif dig and turtle.digDown() then
        if turtle.down() then
            _G.relativePosition.depth = _G.relativePosition.depth - 1
            return true
        end
    end
    return false
end

function lib.goTo(x,z,depth, xd, zd)
    print(string.format("Going to %d:%d:%d ; %d:%d",x,z,depth,xd,zd))
    print(string.format("      at:%d:%d:%d ; %d:%d",
                                _G.relativePosition.xPos,
                                _G.relativePosition.zPos,
                                _G.relativePosition.depth,
                                _G.relativePosition.xDir,
                                _G.relativePosition.zDir ))
    if _G.relativePosition.xPos > x then
        while _G.relativePosition.xDir ~= -1 do
            lib.turnLeft()
        end
        while _G.relativePosition.xPos > x do
            lib.goForward(true)
            sleep(0.5)
        end
    elseif _G.relativePosition.xPos < x then
        while _G.relativePosition.xDir ~= -1 do
            lib.turnLeft()
        end
        while _G.relativePosition.xPos < x do
            lib.goForward(true)
            sleep(0.5)
        end        
    end
    if _G.relativePosition.zPos > z then
        while _G.relativePosition.zDir ~= -1 do
            lib.turnLeft()
        end
        while _G.relativePosition.zPos > z do
            lib.goForward(true)
            sleep(0.5)
        end
    elseif _G.relativePosition.zPos < z then
        while _G.relativePosition.zDir ~= -1 do
            lib.turnLeft()
        end
        while _G.relativePosition.zPos < z do
            lib.goForward(true)
            sleep(0.5)
        end        
    end
    while _G.relativePosition.depth < depth do 
        lib.goUp(true)
    end
    while _G.relativePosition.depth > depth do
        lib.goDown(true)
    end
    while _G.relativePosition.zDir ~= zd or _G.relativePosition.xDir ~= xd do
        lib.turnLeft()
    end
end


function lib.goHome()
    lib.goTo(0,0,0,1,0)
end

return lib