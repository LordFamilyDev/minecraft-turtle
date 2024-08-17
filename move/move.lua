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

function turnLeft()
    turtle.turnLeft()
    xDir, zDir = zDir, -xDir
end

function turnRight()
    turtle.turnRight()
    xDir, zDir = -zDir, xDir
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