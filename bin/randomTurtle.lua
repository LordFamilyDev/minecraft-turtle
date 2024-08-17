local move = require("/lib/move")

move.refuel()

while (true) do
    opt = math.random(1, 5)
    move.refuel()
    if opt == 1 then
        move.goForward(true)
    elseif opt == 2 then
        move.goUp(true)
    elseif opt == 3 then
        move.goDown(true)
    elseif opt == 4 then
        move.turnLeft()
    elseif opt == 5 then
        move.turnRight()
    end
    move.dumpTrash()
end