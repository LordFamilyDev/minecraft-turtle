
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
    elseif not dig then
        return false
    end

    --dig enabled and want to move forward, dig until shit stops falling if possible
    while not turtle.forward() do
        -- Attempt to dig the block in front of the turtle
        if turtle.detect() then
            if not turtle.dig() then
                print("Undiggable block")
                return false
            end
            -- Check if a gravity block (like sand or gravel) falls after digging
            while turtle.detect() do
                turtle.dig()  -- Keep digging until no more blocks are in front
                sleep(0.5)    -- Give the falling block a moment to settle
            end
        else
            -- If the turtle can't move forward and there's nothing to dig, return false
            return false
        end
    end

    --successful move forward
    _G.relativePosition.xPos = _G.relativePosition.xPos + _G.relativePosition.xDir
    _G.relativePosition.zPos = _G.relativePosition.zPos + _G.relativePosition.zDir
    return true
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
        while _G.relativePosition.xDir ~= 1 do
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
        while _G.relativePosition.zDir ~= 1 do
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

lib.moveMemory = ""

function lib.clearMoveMemory()
    lib.moveMemory = ""
end

function lib.memPlayback(revFlag, digFlag)
    if revFlag then
        lib.turnRight()
        lib.turnRight()

        lib.macroMove(lib.reverseMacro(lib.moveMemory),digFlag)

        lib.turnRight()
        lib.turnRight()
    else
        lib.macroMove(lib.moveMemory,digFlag)
    end
end

function lib.reverseMacro(moveSequence)
    local revMoveSequence = ""
    for i = #moveSequence, 1, -1 do
        local char = moveSequence:sub(i, i)
        if char == "R" then
            revMoveSequence = revMoveSequence .. "L"
        elseif char == "L" then
            revMoveSequence = revMoveSequence .. "R"
        elseif char == "U" then
            revMoveSequence = revMoveSequence .. "D"
        elseif char == "D" then
            revMoveSequence = revMoveSequence .. "U"
        end
    end

    return revMoveSequence
end

--Valid move chars: F,R,L,U,D
function lib.charMove(moveChar, memFlag, digFlag)
    if moveChar == "F" then
        if not lib.goForward(digFlag) then
            return false
        end
    elseif moveChar == "U" then
        if not lib.goUp(digFlag) then
            return false
        end
    elseif moveChar == "D" then
        if not lib.goDown(digFlag) then
            return false
        end
    elseif moveChar == "R" then
        lib.turnRight()
    elseif moveChar == "L" then
        lib.turnLeft()
    else
        print("Unrecognized command: " .. moveChar)
        return false
    end

    if memFlag then
        lib.moveMemory = lib.moveMemory .. moveChar
    end
end

--Takes a sequency of chars eg: "FFRFUDR" and performs the motion sequence (returns mid motion if any move fails)
--Returns true if sequence completed
--Valid move chars: F,R,L,U,D
--Note: I considered adding dig and place here, but think there should be a different library for structure macros
function lib.macroMove(moveSequence, memFlag, digFlag)
    for i = 1, #moveSequence do
        local char = moveSequence:sub(i, i)
        lib.refuel()
        if not lib.charMove(char, memFlag, digFlag) then
            print("Move macro failed at: " .. i)
            return false
        end
    end
    return true
end

return lib