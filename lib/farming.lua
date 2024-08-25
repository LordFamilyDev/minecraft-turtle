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
    while move.getdepth() < 2 do
        move.goUp(true)
    end
    while move.getdepth() > 2 do
        move.goTo(0,0,move.getdepth(),1,0)
        move.spiralOut(10)
        move.goDown(true)
    end
end

function farm.sweepUp(radius)
end

function farm.fillFurnace(dir)
    woodCount = itemTypes.getWood()
    if woodCount then
        if dir == "Down" then 
            turtle.dropDown(woodCount/3)
        elseif dir == "Forward" then
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
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if not itemTypes.isItemInList(item.name, itemTypes.saplingTypes) then
                turtle.select(slot)
                local count = turtle.getItemCount()
                turtle.dropDown(count)
            end
        end
    end
end




return farm