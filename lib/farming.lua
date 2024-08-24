local move = require("/lib/move")

local farm = {}

function farm.waitForTree()
    isTree = false
    while ~isTree do
        isTree, treeInfo = turtle.inspect()
        print("Sleeping for a minute")
        sleep(60)
end

function farm.mineTree()
    --move into the trunk
    move.goForward(true)
    turtle.digDown()
    sleep(0.5)
    turtle.suckDown()
    local blockUp, info = turtle.inspectUp()
    while blockUp and (
        info.name = "minecraft.oak_log" or
        info.name = "minecraft.oak_leaves"
        move.goUp(true)
        sleep(0.5)
    )

end


return farm