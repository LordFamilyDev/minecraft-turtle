local move = require("/lib/move")
local itemTypes = require("/lib/item_types")

local farm = {}


function farm.waitForTree()
    treePresent, treeType =  itemTypes.isTreeFwd()
    while not  treePresent do
        print("No Tree... Sleeping..")
        sleep(10)
        move.turnRight()
        treePresent, treeType = itemTypes.isTreeFwd()
    end
    return treeType
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
    local blockUp, info = turtle.inspectUp()
    while itemTypes.isTreeUp() do
        move.goUp(true)
        sleep(0.1)
    end
end

function farm.mineLeaves()
    local depth = move.getdepth() 
    while depth > 0 do
        move.pathTo(0,0,move.getdepth(),true)
        move.spiralOut(6)
        depth = depth - 1
    end
end

function farm.plant(locationList, itemTypeList)
end

--assumes you are 1 above ground level (above the sapling)
function farm.sweepUp(radius)
    move.spiralOut(radius,true)
    move.pathTo(0,0,0)
end

function farm.fillFurnace(dir)
    -- woodCount = itemTypes.getWood()
    -- if woodCount then
    --     if dir == "Down" then 
    --         turtle.dropDown(woodCount/3)
    --     elseif dir == "Forward" then
    --         turtle.drop(woodCount/3)
    --     end
    -- end
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