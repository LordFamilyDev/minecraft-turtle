local move = require("/lib/move")
local dig = false

move.refuel()
--Get us away from the spawn point
for i = 1, 10 do
    print("Onward!!!")
    move.goForward()
end

while (true) do
    if move.distToHome() > 50 then
        move.goHome()
    end
    print("Dance!")
    dir = math.random(1, 5)
    dist = math.random(1, 10)
    if turtle.getFuelLevel() < 10 then
        move.refuel()
    end
    if dir == 1 then
        print("Forward:" .. dist)
        for i = 1, dist do
            move.goForward(dig)
        end
    elseif dir == 2 then
        print("Up:" .. dist)
        for i = 1, dist do
            move.goUp(dig)
        end
    elseif dir == 3 then
        print("Down:" .. dist)
        for i = 1, dist do
            move.goDown(dig)
        end
    elseif dir == 4 then
        print("Left")
        move.turnLeft()
        for i = 1, dist do
            move.goForward(dig)
        end
    elseif dir == 5 then
        print("Right")
        move.turnRight()
        for i = 1, dist do
            move.goForward(dig)
        end
    end
    if(dig) then
        move.dumpTrash()
    end
    print("Fuel remaining" .. turtle.getFuelLevel())
    sleep(3.0)
    
end