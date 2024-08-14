local depth = 0
local xPos,zPos = 0,0
local xDir,zDir = 0,1


function distToHome()
    return math.abs(xPos) + math.abs(zPos) + depth + 1
end


function turnLeft()
    turtle.turnLeft()
    xDir,zDir = -zDir,xDir
end

function turnRight()
    turtle.turnRight()
    xDir,zDir = zDir,-xDir
end

function goUp(dig)
    if turtle.up() then
        depth = depth + 1
        return true
    elseif dig and turtle.digUp() then
        turtle.up()
        depth = depth + 1
        return true
    end
    return false
end

function goDown(dig)
    if turtle.down() then
        depth = depth - 1
        return true
    elseif dig and turtle.digDown() then
        turtle.down()
        depth = depth - 1
        return true
    end
    return false
end