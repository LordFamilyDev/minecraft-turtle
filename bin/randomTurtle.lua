local move = require("/lib/move")
local dig = false

move.refuel()
--Get us away from the spawn point
for i = 1, 20 do
    move.goForward()
end

while (true) do
    dir = math.random(1, 5)
    dist = math.random(1, 10)
    if turtle.getFuelLevel() < 10 then
        move.refuel()
    end
    if opt == 1 then
        for i = 1, dist do
            move.goForward(dig)
        end
    elseif opt == 2 then
        for i = 1, dist do
            move.goUp(dig)
        end
    elseif opt == 3 then
        for i = 1, dist do
            move.goDown(dig)
        end
    elseif opt == 4 then
        move.turnLeft()
        for i = 1, dist do
            move.goForward(dig)
        end
    elseif opt == 5 then
        move.turnRight()
        for i = 1, dist do
            move.goForward(dig)
        end
    end
    if(dig) then
        move.dumpTrash()
    end

end