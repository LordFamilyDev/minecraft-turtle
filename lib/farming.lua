local move = require("/lib/move")

local farm = {}

function farm.waitForTree()
    isTree = false
    isTree, treeInfo = turtle.inspect()
    while not isTree do
        isTree, treeInfo = turtle.inspect()
        print("Sleeping for a minute")
        sleep(60)
    end
end

function farm.mineTree()
    --move into the trunk
    move.goForward(true)
    turtle.digDown()
    sleep(0.5)
    turtle.suckDown()
    local blockUp, info = turtle.inspectUp()
    while blockUp and 
        (info.name == "minecraft:oak_log" or
        info.name == "minecraft:oak_leaves")  do
        blockUp, info = turtle.inspectUp()
        move.goUp(true)
        sleep(0.5)
        end
end


return farm