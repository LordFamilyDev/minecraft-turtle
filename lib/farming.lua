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

function farm.isTree()
    return itemTypes.isTreeFwd()
end

function farm.mineTree()
    --move into the trunk
    move.goForward(true)
    turtle.digDown()
    sleep(0.5)
    turtle.suckDown()
    if itemTypes.selectSapling() then
        turtle.placeDown()
    end
    local blockUp, info = turtle.inspectUp()
    while itemTypes.isTreeUp() do
        move.goUp(true)
        sleep(0.5)
    end
end

function farm.mineLeaves()
end

function farm.sweepUp(radius)
end

function farm.fillFurnace(dir)
    woodCount = itemTypes.getWood()
    if woodCount then
        if dir = "Down" then 
            turtle.dropDown(woodCount/3)
        elseif dir = "Forward" then
            turtle.drop(woodCount/3)
        end
    end
end

function farm.dumpWood()
    while itemTypes.getWood() do
        turtle.dropDown()
    end
end

function farm.dumpCharcoal()
    itemTypes.selectItem("minecraft:charcoal")
    move.refuel()
    while itemTypes.selectItem("minecraft:charcoal") do
        turtle.dropDown()
    end
end

function farm.dumpOther()
    for slot = 1
end




return farm