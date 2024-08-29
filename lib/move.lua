itemTypes = require("/lib/item_types")
lib_debug = require("/lib/lib_debug")
lib_debug.set_verbose(false)

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

function lib.setPos(x,z,d,xd,zd)
    _G.relativePosition.depth = d
    _G.relativePosition.xPos = x
    _G.relativePosition.zPos = z
    if xd~= nil and zd ~= nil then
        _G.relativePosition.xDir = xd
        _G.relativePosition.zDir = zd
    end
end


function lib.getDirRight(x, z)
    return -z, x
end

function lib.getDirLeft(x, z)
    return z, -x
end

lib.whitelist = {}
lib.blacklist = itemTypes.noMine
lib.tether = 34

function lib.distToHome()
    return math.abs(_G.relativePosition.xPos) + math.abs(_G.relativePosition.zPos) + math.abs(_G.relativePosition.depth)
end

function lib.maxDimToHome()
    local val = math.abs(_G.relativePosition.xPos)
    if math.abs(_G.relativePosition.zPos) > val then
        val = math.abs(_G.relativePosition.zPos)
    end
    if math.abs(_G.relativePosition.depth) > val then
        val = math.abs(_G.relativePosition.depth)
    end
    return val
end

function lib.setTether(t)
    lib.tether = t
end

function lib.getTether()
    return lib.tether
end

function lib.getDir()
    return _G.relativePosition.xDir, _G.relativePosition.zDir
end

function lib.getTurnCount(xC, zC, xT, zT)
    local turns = 0
    local x, z = xC, zC
    while x ~= xT or z ~= zT do
        x, z = lib.getDirRight(x, z)
        turns = turns + 1
    end
    return turns
end

function lib.faceDir(x, z)
    local turns = lib.getTurnCount(_G.relativePosition.xDir, _G.relativePosition.zDir, x, z)    
    if turns == 1 then
        turnRight()
    elseif turns == 2 then
        turnRight()
        turnRight()
    elseif turns == 3 then
        turnLeft()
    end
end

function lib.getPos()
    return _G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth
end

function lib.getdepth()
    return _G.relativePosition.depth
end

function lib.addWhitelist(whiteListItem)
    if type(whiteListItem) == "string" then
        table.insert(lib.whitelist, whiteListItem)
    elseif type(whiteListItem) == "table" then
        for _, item in ipairs(whiteListItem) do
            table.insert(lib.whitelist, item)
        end
    else
        error("Invalid input: must be a string or a table")
    end
end

function lib.clrWhitelist()
    lib.whitelist = {}
end

function lib.addBlacklist(blackListItem)
    if type(blackListItem) == "string" then
        table.insert(lib.blacklist, blackListItem)
    elseif type(blackListItem) == "table" then
        for _, item in ipairs(blackListItem) do
            table.insert(lib.blacklist, item)
        end
    else
        error("Invalid input: must be a string or a table")
    end
end

function lib.clrBlacklist()
    lib.blacklist = {}
end


function lib.isWhitelist(direction)
    -- If the whitelist is empty, return true
    if #lib.whitelist == 0 then
        return true
    end

    local success, data
    
    if direction == "up" then
        success, data = turtle.inspectUp()
    elseif direction == "down" then
        success, data = turtle.inspectDown()
    else
        success, data = turtle.inspect()
    end
    
    if not success then
        return true
    end
    
    --print("Checking: "..data.name)

    return itemTypes.isItemInList(data.name, lib.whitelist)
end

function lib.isBlacklist(direction)
    if #lib.blacklist == 0 then
        return false
    end

    local success, data

    if direction == "up" then
        success, data = turtle.inspectUp()
    elseif direction == "down" then
        success, data = turtle.inspectDown()
    else
        success, data = turtle.inspect()
    end
    
    if not success then
        return false
    end
    
    return itemTypes.isItemInList(data.name, lib.blacklist)
end

function lib.canDig(dir)
    -- Check if the block is blacklisted
    if lib.isBlacklist(dir) then
        --print("Block Blacklisted")
        return false
    end

    -- Check if the block is whitelisted
    if lib.isWhitelist(dir) then
        return true
    end

    --print("Block Not Whitelisted")
    return false
end

function lib.overTether()
    if lib.tether > 0 and lib.distToHome() > lib.tether then
        print("Tether reached")
        return true
    end
    return false
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
    _G.relativePosition.xDir, _G.relativePosition.zDir = lib.getDirLeft(_G.relativePosition.xDir,  _G.relativePosition.zDir)
end

function lib.turnRight()
    turtle.turnRight()
    _G.relativePosition.xDir, _G.relativePosition.zDir = lib.getDirRight(_G.relativePosition.xDir, _G.relativePosition.zDir)
end

function lib.goForward(dig)
    if lib.overTether() then
        print("Past My Tether.")
        return false
    end
    if turtle.forward() then
        _G.relativePosition.xPos = _G.relativePosition.xPos + _G.relativePosition.xDir
        _G.relativePosition.zPos = _G.relativePosition.zPos + _G.relativePosition.zDir
        return true
    elseif not dig then
        return false
    end

    --dig enabled and want to move forward,

    -- Check the lists
    if not lib.canDig("forward") then
        return false
    end
    --dig until shit stops falling if possible
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

function lib.goBackwards(dig)
    if lib.overTether() then
        return false
    end
    if turtle.back() then
        _G.relativePosition.xPos = _G.relativePosition.xPos - _G.relativePosition.xDir
        _G.relativePosition.zPos = _G.relativePosition.zPos - _G.relativePosition.zDir
        return true
    elseif not dig then
        return false
    end

    lib.turnRight()
    lib.turnRight()
    local moveResult = lib.goForward(dig)
    lib.turnRight()
    lib.turnRight()

    return moveResult
end

function lib.goLeft(digFlag, turnFlag)
    lib.turnLeft()
    local moveResult = lib.goForward(digFlag)
    if turnFlag then
        lib.turnRight()
    end
    return moveResult
end

function lib.goRight(digFlag, turnFlag)
    lib.turnRight()
    local moveResult = lib.goForward(digFlag)
    if turnFlag then
        lib.turnLeft()
    end
    return moveResult
end

function lib.goUp(dig)
    if lib.overTether() then
        return false
    end
    if turtle.up() then
        _G.relativePosition.depth = _G.relativePosition.depth + 1
        return true
    elseif not dig then
        return false
    end

    --dig enabled and want to move up, dig until shit stops falling if possible
    -- Check the lists
    if not lib.canDig("up") then
        return false
    end

    while not turtle.up() do
        -- Attempt to dig the block above the turtle
        if turtle.detectUp() then
            if not turtle.digUp() then
                print("Undiggable block")
                return false
            end
            -- Check if a gravity block (like sand or gravel) falls after digging
            while turtle.detectUp() do
                turtle.digUp()  -- Keep digging until no more blocks are in front
                sleep(0.5)    -- Give the falling block a moment to settle
            end
        else
            -- If the turtle can't move up and there's nothing to dig, return false
            return false
        end
    end

    --successful move up
    _G.relativePosition.depth = _G.relativePosition.depth + 1
    return true
end

function lib.goDown(dig)
    if lib.overTether() then
        return false
    end
    if turtle.down() then
        _G.relativePosition.depth = _G.relativePosition.depth - 1
        return true
    elseif not dig then
        return false
    end

    -- Check the lists
    if not lib.canDig("down") then
        return
    end
    if turtle.digDown() then
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
    
    --Fix depth first in case dug into bedrock (usually up means freedom)
    while _G.relativePosition.depth < depth do 
        lib.goUp(true)
    end
    while _G.relativePosition.depth > depth do
        lib.goDown(true)
    end

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
    
    while _G.relativePosition.zDir ~= zd or _G.relativePosition.xDir ~= xd do
        lib.turnLeft()
    end
end


function lib.goHome()
    lib.goTo(0,0,0,1,0)
end


-- Directions from the turtle's perspective
local allDirectionsFU = {
        {1,0,0}, --forward
        {0,0,1}, --up
        {0,0,-1}, --down
        {0,1,0}, --right
        {0,-1,0}, --left
        {-1,0,0} --back
    }
local allDirectionsFD = {
        {1,0,0}, --forward
        {0,0,1}, --up
        {0,0,-1}, --down
        {0,1,0}, --right
        {0,-1,0}, --left
        {-1,0,0} --back
    }
local allDirectionsUDF = {
        {0,0,1}, --up
        {0,0,-1}, --down
        {1,0,0}, --forward
        {0,1,0}, --right
        {0,-1,0}, --left
        {-1,0,0} --back
    }
local allDirectionsDUF = {
        {0,0,1}, --up
        {0,0,-1}, --down
        {1,0,0}, --forward
        {0,1,0}, --right
        {0,-1,0}, --left
        {-1,0,0} --back
    }

local allDirectionsLIN = {
        {1,0,0}, --forward
        {0,1,0}, --right
        {0,-1,0}, --left
        {-1,0,0} --back
    }

local BIG_NUMBER = 1000000
-- Helper function to calculate Manhattan distance
function lib.manhattanDistance(x1, z1, d1, x2, z2, d2)
    return ( math.abs((x1 - x2)) + math.abs((z1 - z2)) + math.abs((d1 - d2)) )
end

function lib.getIndex(x, z, d)
    return x .. "," .. z .. " ," .. d
end

function lib.invert(xD, zD, dD)
    return -xD, -zD, -dD
end

-- get Neighbor Scores
function lib.isInTable(tbl, item)
    for _, value in ipairs(tbl) do
        if value == item then
            return true
        end
    end
    return false
end

function lib.getNeighborScores(currentPos, goal, obstacles, visited, allDirections)
    local neighborScores = {}
    local x, z, d = unpack(currentPos)
    local xT, zT, dT = unpack(goal)
    for i = 1, #allDirections do
        local xD, zD, dD = unpack(allDirections[i]) 
        local xN, zN, dN = x + xD, z + zD, d + dD
        local index = lib.getIndex(xN, zN, dN)
        score = BIG_NUMBER
        if obstacles[index] ~= nil then
            score = BIG_NUMBER
        elseif visited[index] ~= nil then
            score = BIG_NUMBER
        else
            score = lib.manhattanDistance(xN, zN, dN, xT, zT, dT)
        end
        table.insert(neighborScores, {xN, zN, dN, xD, zD, dD, score})
    end
    return neighborScores
end

function lib.getLowestScore(scores)
    local lowest = scores[1]
    local index = 1
    for i = 2, #scores do
        if scores[i][7] < lowest[7] then
            index = i
            lowest = scores[i]
        end
    end
    return lowest, index, lowest[7] == BIG_NUMBER
end


function lib.step(xD, zD, dD, digFlag)
    if turtle.getFuelLevel() == 0 then
        error("Out of Fuel")
    end
    local err = false
    if xD == 1 then
        err = lib.goForward(digFlag)
    elseif xD == -1 then
        err = lib.goBackwards(digFlag)
    elseif zD == 1 then
        err = lib.goRight(digFlag, true)
    elseif zD == -1 then
        err = lib.goLeft(digFlag, true)
    elseif dD == 1 then
        err = lib.goUp(digFlag)
    elseif dD == -1 then
        err = lib.goDown(digFlag)
    end
    lib_debug.print_debug("Stepping"..xD.." "..zD.." "..dD .. " ::".. tostring(err))
    return err
end

-- Finds path to xzd coordinates based on relative position
lib.aggressiveness = 3

function lib.pathTo(x, z, d, digFlag, dPrefStr)
    local path = {}
    local obstacles = {}
    local visited = {}
    local start = {_G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth}
    local goal = {x, z, d}
    local current = start
    local pathIndex = 1
    local localMinScore = BIG_NUMBER

    local dirPref = allDirectionsFU
    if dPrefStr ~= nil then
        if dPrefStr == "FD" then
            dirPref = allDirectionsFD
        elseif dPrefStr == "FU" then
            dirPref = allDirectionsFU
        elseif dPrefStr == "UDF" then
            dirPref = allDirectionsUDF
        elseif dPrefStr == "DUF" then
            dirPref = allDirectionsDUF
        elseif dPrefStr == "LIN" then
            dirPref = allDirectionsLIN
        end
    end



    local currentIndex = lib.getIndex(current[1],current[2],current[3])
    local goalIndex = lib.getIndex(goal[1],goal[2],goal[3])
    visited[currentIndex] = true
    while not (currentIndex == goalIndex) do
        -- read()
        
        local neighborScores = lib.getNeighborScores(current, goal, obstacles, visited, dirPref)

        -- for i = 1, #neighborScores do
        --     print("N:",unpack(neighborScores[i]))
        -- end 
        -- read()
        lib_debug.print_debug("current:" .. currentIndex .. "goal:" .. goalIndex)

        while #neighborScores > 0 do
            local n, scoreIndex, deadend = lib.getLowestScore(neighborScores)
            lib_debug.print_debug("next:",unpack(n),scoreIndex,deadend)
            if n[7] < localMinScore then
                localMinScore = n[7] 
            end

            if n[7] > (localMinScore + lib.aggressiveness) then
                print("!!!BHailing. No path found!!!")
                return false
            end 
                        
            if deadend then
                if #path == 0 then
                    print("!!!No path found!!!")
                    return false
                else
                    lib_debug.print_debug("backtracking:")
                    obstacles[currentIndex] = true
                    n = path[1]
                    table.remove(path, 1)
                    local xN, zN, dN, xD, zD, dD, s = unpack(n)
                    
                    -- no need to chech other neighbor scores
                    if lib.step(xD, zD, dD, true) then -- if we are backtracking...dig through shit in our way
                        current = {_G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth}
                        break
                    else
                        print("Turtle stuck")
                        return false
                    end
                end
            end

            local xN, zN, dN, xD, zD, dD, s = unpack(n)
            local nextIndex = lib.getIndex(xN, zN, dN)
            lib_debug.print_debug("trying:" .. nextIndex .. "Score" .. s )
                
            if lib.step(xD, zD, dD, digFlag) then
                -- if sucess add to path and find the next step
                xP, zP, dP = lib.invert(xD, zD, dD)
                table.insert(path, 1, {current[1],current[2],current[3],xP,zP,dP,0} )
                current = {_G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth}
                currentIndex = lib.getIndex(current[1],current[2],current[3])
                visited[currentIndex] = true
                break
            else
                --make sure we havent been given the impossible
                if nextIndex == goalIndex then
                    print("We Got To: " .. goalIndex)
                    return true
                end
                -- else add to obstacles and try next lowest score
                lib_debug.print_debug("Adding to obstacles"..nextIndex)
                obstacles[nextIndex] = true
                table.remove(neighborScores, scoreIndex)
            end
        end
        if #neighborScores == 0 then
            print("!!!No path found!!!")
            return false
        end
    end
    print("We Got To: " .. goalIndex)
    return true
end


function lib.spiralOut(radius, sweep)
    local side = 1
    local steps = 1
    local x, z, d = lib.getPos()
    local xd, zd = lib.getDir()
    while side <= radius * 2 do
      if sweep then
        turtle.suckDown()
      end
      for i = 1, steps do
        x = x + xd
        z = z + zd
        print("Pathing to: "..x..","..z..","..d)
        lib.pathTo(x, z, d, true)
      end
      
      xd, zd = lib.getDirLeft(xd, zd)

      if side % 2 == 0 then
        steps = steps + 1
      end
      
      side = side + 1
    end
end

lib.moveMemory = ""

function lib.clearMoveMemory()
    lib.moveMemory = ""
end

function lib.memPlayback(revFlag, digFlag)
    if revFlag then
        lib.turnRight()
        lib.turnRight()

        lib.macroMove(lib.reverseMacro(lib.moveMemory),false,digFlag)

        lib.turnRight()
        lib.turnRight()
    else
        lib.macroMove(lib.moveMemory,false,digFlag)
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
        elseif char == "F" then
            revMoveSequence = revMoveSequence .. "F"
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

    return true
end

--Takes a sequency of chars eg: "FFRFUDR" and performs the motion sequence (returns mid motion if any move fails)
--Returns true if sequence completed
--Valid move chars: F,R,L,U,D
--Note: I considered adding dig and place here, but think there should be a different library for structure macros
function lib.macroMove(moveSequence, memFlag, digFlag)
    print(moveSequence)
    for i = 1, #moveSequence do
        local char = moveSequence:sub(i, i)
        if not lib.charMove(char, memFlag, digFlag) then
            print("Move macro failed at: " .. i)
            return false
        end
    end
    return true
end

return lib