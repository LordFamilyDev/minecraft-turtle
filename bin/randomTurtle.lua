local move = require("/lib/move.lua")

move.refuel()

while (true) do
    opt = math.random(1, 5)
    move.refuel()
    if opt == 1 then
        move.forward(true)
    elseif opt == 2 then
        move.up(true)
    elseif opt == 3 then
        move.down(true)
    elseif opt == 4 then
        move.turnLeft()
    elseif opt == 5 then
        move.turnRight()
    end
    move.dumpTrash()
end