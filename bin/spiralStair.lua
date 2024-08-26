local move = require ("/lib/move")
local targetDepth = -48  -- needs to be negative to work
-- note : turtle starts stairs one block infront of it
-- spirals to left by default change move.turnleft to move.turnright
local function startStair()
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.turnLeft()
end

local function make2Stairtorch()
    move.goForward(true)
    turtle.digUp()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:torch" 
            then
            turtle.select(slot)
            turtle.turnLeft()
            turtle.dig()
            turtle.place()
            turtle.turnRight()
            break
        end
    end
    move.goDown(true)
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.turnLeft()
end
-- starts to make full staircase
local function makeStaircase()
    move.setHome()
    print("Home set")
    startStair()
    while move.getdepth() > targetDepth
    do  make2Stairtorch()
    end
end
makeStaircase()