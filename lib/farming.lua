local move = require("/lib/move")
local itemTypes = require("/lib/item_types")

local farm = {}


function farm.waitForTree()
    while not itemTypes.isTreeFwd() do
        print("No Tree... Sleeping..")
        sleep(10)
        move.turnRight()
    end
end

function farm.mineTree()
    --move into the trunk
    move.goForward(true)
    turtle.digDown()
    sleep(0.5)
    turtle.suckDown()
    local blockUp, info = turtle.inspectUp()
    while itemTypes.isTreeUp() do
        move.goUp(true)
        sleep(0.5)
    end
end

function farm.mineLeaves()
end

return farm