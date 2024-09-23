itemTypes = require("/lib/item_types")
lib_debug = require("/lib/lib_debug")

local debugFlag = false 

lib_debug.set_verbose(debugFlag)

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
    --return -z, x
    if x == 1 then
        return 0, 1
    elseif x == -1 then
        return 0, -1
    elseif z == 1 then
        return -1, 0
    elseif z == -1 then
        return 1, 0
    end
end

function lib.getDirLeft(x, z)
    return z, -x
end

--default off, activate as needed for given script
lib.whitelist = {}
lib.blacklist = {}
lib.tether = 0
lib.tetherIs2d = false

function lib.distToHome(xyOnlyFlag)
    if xyOnlyFlag then
        return math.abs(_G.relativePosition.xPos) + math.abs(_G.relativePosition.zPos)
    else
        return math.abs(_G.relativePosition.xPos) + math.abs(_G.relativePosition.zPos) + math.abs(_G.relativePosition.depth)
    end
    
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

function lib.setTether(t, flag2d)
    lib.tether = t
    if flag2d then
        lib.tetherIs2d = true
    else
        lib.tetherIs2d = false
    end
end

function lib.getTether()
    return lib.tether
end

function lib.getPos()
    return _G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth
end

function lib.getdepth()
    return _G.relativePosition.depth
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
        if turns > 3 then
            return -1
        end
    end
    return turns
end

function lib.getDirTo(x,z,d)
    local xn, zn, dn = lib.getPos()
    local xd = x - xn
    local zd = z - zn
    local dd = d - dn
    if xd == 0 then xd = 0 elseif xd > 0 then xd = 1 else xd = -1 end
    if zd == 0 then zd = 0 elseif zd > 0 then zd = 1 else zd = -1 end
    if dd == 0 then dd = 0 elseif dd > 0 then dd = 1 else dd = -1 end
    lib_debug.print_debug("To:",x,z,d,"From",xn,zn,dn,"dir:",xd,zd,dd)
    return xd,zd,dd
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
    if lib.tetherIs2d then
        if lib.tether > 0 and lib.distToHome(true) > lib.tether then
            print("Tether reached")
            return true
        end
    else
        if lib.tether > 0 and lib.distToHome() > lib.tether then
            print("Tether reached")
            return true
        end
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

function lib.turnTo(x, z)
    local turns = lib.getTurnCount(_G.relativePosition.xDir, _G.relativePosition.zDir, x, z)    
    if turns == 0 then
        return true
    elseif turns == 1 then
        lib.turnRight()
    elseif turns == 2 then
        lib.turnRight()
        lib.turnRight()
    elseif turns == 3 then
        lib.turnLeft()
    else
        return false
    end
    
    return true

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
    
    --Fix depth first in case dug into bedrock (usually up means freedom)
    while _G.relativePosition.depth < depth do 
        lib.goUp(true)
    end
    while _G.relativePosition.depth > depth do
        lib.goDown(true)
    end

    while _G.relativePosition.xPos > x do
        lib.turnTo(-1,0)
        lib.goForward(true)
        sleep(0.5)
    end

    while _G.relativePosition.xPos < x do
        lib.turnTo(1,0)
        lib.goForward(true)
        sleep(0.5)
    end

    while _G.relativePosition.zPos > z do
        lib.turnTo(0,-1)
        lib.goForward(true)
        sleep(0.5)
    end

    while _G.relativePosition.zPos < z do
        lib.turnTo(0,1)
        lib.goForward(true)
        sleep(0.5)
    end
    
    lib.turnTo(xd,zd)
end


function lib.goHome()
    --turn off tether to allow turtle to go home
    local tempTether = lib.getTether()
    lib.setTether(0)
    lib.goTo(0,0,0,1,0)
    lib.setTether(tempTether)
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

local VISITED = 1000000
local OBSTACLE = VISITED * 2
-- Helper function to calculate Manhattan distance
function lib.manhattanDistance(x1, z1, d1, x2, z2, d2)
    return ( math.abs((x1 - x2)) + math.abs((z1 - z2)) + math.abs((d1 - d2)) )
end

function lib.squaredDistance(x1, z1, d1, x2, z2, d2)
    return ( math.sqrt( math.pow(x1 - x2,2) + math.pow(z1 - z2,2) + math.pow(d1 - d2,2)  ))
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


local SCORE_INDEX = 4
function lib.getNeighborScores(currentPos, goal, obstacles, visited, allDirections)
    local neighborScores = {}
    local x, z, d = unpack(currentPos)
    local xT, zT, dT = unpack(goal)
    for i = 1, #allDirections do
        local xD, zD, dD = unpack(allDirections[i]) 
        local xN, zN, dN = x + xD, z + zD, d + dD
        local index = lib.getIndex(xN, zN, dN)
        score = OBSTACLE
        if obstacles[index] ~= nil then
            score = OBSTACLE
        elseif visited[index] ~= nil then
            -- score = VISITED + lib.manhattanDistance(xN, zN, dN, xT, zT, dT)
            score = visited[index]
        else
            score = lib.squaredDistance(xN, zN, dN, xT, zT, dT)
        end
        table.insert(neighborScores, {xN, zN, dN, score})
        lib_debug.print_debug("Index:",index, "score:",score)
    end
    return neighborScores
end

function lib.getLowestScore(scores)
    local lowest = scores[1]
    local debug = "Scores: "
    local sum = lowest[SCORE_INDEX]
    debug = debug .. sum .. ","
    local index = 1
    lib_debug.print_debug("Got Scores: ",#scores)
    for i = 2, #scores do
        if scores[i][SCORE_INDEX] < lowest[SCORE_INDEX] then
            index = i
            lowest = scores[i]
        end
        if scores[i][SCORE_INDEX] ~= OBSTACLE then
            sum = sum + scores[i][SCORE_INDEX]
        end
        debug = debug .. i .. ":" .. scores[i][SCORE_INDEX] .. ","
        --lib_debug.print_debug(i, scores[i][SCORE_INDEX])
    end
    --lib_debug.print_debug(debug)
    if debugFlag then io.read() end
    return lowest, index, lowest[SCORE_INDEX] == OBSTACLE, sum
end

function lib.step(xD, zD, dD, digFlag)
    if turtle.getFuelLevel() == 0 then
        error("Out of Fuel")
    end
    local err = false
    if lib.turnTo(xD, zD) then
        err = lib.goForward(digFlag)
    elseif dD == 1 then
        err = lib.goUp(digFlag)
    elseif dD == -1 then
        err = lib.goDown(digFlag)
    end
    lib_debug.print_debug("Stepping"..xD.." "..zD.." "..dD .. " ::".. tostring(err))
    return err
end

function lib.stepTo(xT, zT, d, digFlag)
    if turtle.getFuelLevel() == 0 then
        error("Out of Fuel")
    end
    local xD, zD, dD = lib.getDirTo(xT,zT,d)
    lib_debug.print_debug("Going To:",xT,zT,d, "Direction",xD,zD,dD)

    return lib.step(xD,zD,dD, digFlag)
end

-- Finds path to xzd coordinates based on relative position
lib.aggressiveness = OBSTACLE

function lib.pathTo(x, z, d, digFlag, dPrefStr)
    print("Pathing To:",x,z,d)
    local path = {}
    local obstacles = {}
    local visited = {}
    local start = {_G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth}
    local goal = {x, z, d}
    local current = start
    local pathIndex = 1
    local localMinScore = OBSTACLE

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
    visited[currentIndex] = lib.squaredDistance(current[1],current[2],current[3],goal[1],goal[2],goal[3])
    while not (currentIndex == goalIndex) do
        local neighborScores = lib.getNeighborScores(current, goal, obstacles, visited, dirPref)
        lib_debug.print_debug("current:" .. currentIndex .. "goal:" .. goalIndex)

        while #neighborScores > 0 do
            local n, scoreIndex, deadend, hiScore = lib.getLowestScore(neighborScores)
            lib_debug.print_debug("next:",unpack(n),scoreIndex,deadend)
            if n[SCORE_INDEX] < localMinScore then
                localMinScore = n[SCORE_INDEX] 
            end
            
            
            if n[SCORE_INDEX] > OBSTACLE then
                print("!!!Bailing. No path found!!!")
                return false
            end 
            if n[SCORE_INDEX] > (localMinScore + lib.aggressiveness) then
                print("!!!Bailing. No path found!!!")
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
                    local xN, zN, dN, s = unpack(n)
                    
                    -- no need to chech other neighbor scores
                    if lib.stepTo(xN, zN, dN, true) then -- if we are backtracking...dig through shit in our way
                        current = {_G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth}
                        break
                    else
                        print("Turtle stuck")
                        return false
                    end
                end
            end

            local xN, zN, dN, s = unpack(n)
            local nextIndex = lib.getIndex(xN, zN, dN)
            lib_debug.print_debug("trying:" .. nextIndex .. "Score" .. s )
                
            if lib.stepTo(xN, zN, dN, digFlag) then
                -- if sucess add to path and find the next step
                table.insert(path, 1, {current[1],current[2],current[3],0} )
                if visited[currentIndex] == nil then
                    visited[currentIndex] = hiScore
                else
                    visited[currentIndex] = visited[currentIndex] + s
                end
                current = {_G.relativePosition.xPos, _G.relativePosition.zPos, _G.relativePosition.depth}
                currentIndex = lib.getIndex(current[1],current[2],current[3])

                break  --go to next step

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

function lib.floodFill(targetBlockNames, xzOnlyFlag, stepFunction)

    while true do
        if type(stepFunction) == "function" then
            stepFunction()
        end

        --move in first direction that has a block on target list
        local success, blockInfo
        local moveMade = false
        --up
        if not xzOnlyFlag and not moveMade then
            success, blockInfo = turtle.inspectUp()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                if not lib.charMove("U", true, true) then
                    print("move failed")
                    return false
                end
                moveMade = true
            end
        end

        --down
        if not xzOnlyFlag and not moveMade then
            success, blockInfo = turtle.inspectDown()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                if not lib.charMove("D", true, true) then
                    print("move failed")
                    return false
                end
                moveMade = true
            end
        end

        --forward
        if not moveMade then
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                if not lib.charMove("F", true, true) then
                    print("move failed")
                    return false
                end
                moveMade = true
            end
        end

        --left 
        if not moveMade then
            lib.macroMove("L", false, true)
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                lib.appendMoveMem("L")
                if not lib.macroMove("F", true, true) then
                    print("move failed")
                    return false
                end
                moveMade = true
            end
        end

        --back
        if not moveMade then
            lib.macroMove("L", false, true)
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                lib.appendMoveMem("LL")
                if not lib.macroMove("F", true, true) then
                    print("move failed")
                    return false
                end
                moveMade = true
            end
        end

        --right
        if not moveMade then
            lib.macroMove("L", false, true)
            success, blockInfo = turtle.inspect()
            if success and isTargetBlock(blockInfo,targetBlockNames) then
                lib.appendMoveMem("R")
                if not lib.macroMove("F", true, true) then
                    print("move failed")
                    return false
                end
                moveMade = true
            end
        end

        --if none step back one move in memory and look again
        if not moveMade then

            --finish 360 to return to forward facing
            lib.macroMove("L", false, true)

            local turnMoveFlag = false
            while true do
                local lastMove = lib.popBackMoveMem()
                if lastMove == "R" or lastMove == "L" then
                    turnMoveFlag = true
                else
                    turnMoveFlag = false
                end
                if lastMove == nil then
                    return true
                end
                lib.charMove(lib.revMoveChar(lastMove),false,true)
                if not turnMoveFlag then
                    break
                end
            end
        end
    end
end

function lib.spiralOut(radius, stepFunction)
    local side = 1
    local steps = 1
    local x0, z0, d0 = lib.getPos()
    local xd0, zd0 = lib.getDir()
    local x, z, d = lib.getPos()
    local xd, zd = lib.getDir()

    local stepFunctionFlag = false

    while steps <= radius * 2 do
        for i = 1, steps do

            if type(stepFunction) == "function" then
                local tempFlag = stepFunction()
                if tempFlag then
                    stepFunctionFlag = true
                end
            end

            x = x + xd
            z = z + zd
            lib.goTo(x, z, d)
        end
        
        xd, zd = lib.getDirLeft(xd, zd)

        if side % 2 == 0 then
            steps = steps + 1
        end
        
        side = side + 1
    end

    --return to start position
    lib.goTo(x0, z0, d0, xd0, zd0)

    --basically this just returns if the step function did anything on this spiral
    return stepFunctionFlag
end

lib.moveMemory = ""

function lib.clearMoveMemory()
    lib.moveMemory = ""
end

function lib.appendMoveMem(moveSequence)
    lib.moveMemory = lib.moveMemory .. moveSequence
end

function lib.popBackMoveMem()
    if #lib.moveMemory > 0 then
        -- Get the last character
        local lastChar = lib.moveMemory:sub(-1)
        -- Remove the last character from the string
        lib.moveMemory = lib.moveMemory:sub(1, -2)
        -- Return the removed character
        return lastChar
    else
        return nil -- Return nil if the string is empty
    end
end

function lib.memPlayback(revFlag, digFlag)
    if revFlag then
        lib.macroMove(lib.reverseMacro(lib.moveMemory),false,digFlag)
    else
        lib.macroMove(lib.moveMemory,false,digFlag)
    end
end

function lib.reverseMacro(moveSequence)
    local revMoveSequence = ""
    for i = #moveSequence, 1, -1 do
        local char = moveSequence:sub(i, i)
        revMoveSequence = revMoveSequence .. lib.revMoveChar(char)
    end
    return revMoveSequence
end

function lib.revMoveChar(moveChar)
    if moveChar == "R" then
        return "L"
    elseif moveChar == "L" then
        return "R"
    elseif moveChar == "U" then
        return "D"
    elseif moveChar == "D" then
        return "U"
    elseif moveChar == "F" then
        return "B"
    elseif moveChar == "B" then
        return "F"
    end
end

--Valid move chars: F,R,L,U,D,B
function lib.charMove(moveChar, memFlag, digFlag)
    if moveChar == "F" then
        if not lib.goForward(digFlag) then
            return false
        end
    elseif moveChar == "B" then
        if not lib.goBackwards(digFlag) then
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
--Valid move chars: F,R,L,U,D,B
--Note: I considered adding dig and place here, but think there should be a different library for structure macros
function lib.macroMove(moveSequence, memFlag, digFlag)
    --print(moveSequence)
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