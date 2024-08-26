local move = require ("/lib/move")
local depth = _G.relativePosition.depth
local targetDepth = -48  -- needs to be negative to work
-- note : turtle starts stairs one block infront of it
-- spirals to left by default change move.turnleft to move.turnright
local function make3Stair
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.goForward(true)
    turtle.digUp()
    move.goDown(true)
    move.turnLeft
end
-- starts to make full staircase
local function makeStaircase
    move.setHome
    print("Home set")
    while depth > targetDepth
    do make3Stair()
    end
end