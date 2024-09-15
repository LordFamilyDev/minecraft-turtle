m = require("/lib/move")
f = require("/lib/farming")
local itemTypes = require("/lib/item_types")
local lib_debug = require("/lib/lib_debug")
local lib_inv_mgmt = require("/lib/lib_inv_mgmt")


function oakFarm()

--       0       
--
-- 2   c l c     
-- 1    lsl     
-- 0   lsTsl     
-- -1   lsl     
-- -2  c l c      
--      0
-- 2
-- 1    f
-- 0    T
--      l
-- 

    local layout = {
        ["home"] = {0,0,0},
        ["torch"] = {{1,-1,-1},{2,0,-1},{1,1,-1},
                 {0,-2,-1},{0,0,-1},{0,2,-1},
                 {-1,-1,-1},{-2,0,-1},{-1,1,-1}},
        ["logchest"] = {2,2,-1},
        ["charcoalchest"] = {2,-2,-1},
        ["furnace"] = {0,0,1},
        ["trees"] = {{1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0}}
    }
    m.setHome()
    m.addWhitelist(itemTypes.treeBlocks)

    while true do
        ::continue::
        f.waitForTree()
        print("Tree found Mining!")
        f.mineTree()
        print("Get the leaves")
        f.mineLeaves()
        print("Feed the furnace")
        m.pathTo(0, 0, 0, false) --under the furnace
        f.fillFurnace("Up")
        print("Sweep up")
        f.sweepUp(6)
        print("Plant Trees")
        f.plant(itemTypes.saplingTypes, layout["trees"])        
        print("Going Home")
        m.pathTo(0, 0, 0, false)
        sleep(0.5)
    end
end

function megaSpruce()
    --turtle facing left sapling with chest under the turtle
    --turtle must be on south side of saplings (based on mega spruce spawn logic)
    while true do
        m.setHome()
        while not f.isTree() do
            lib_debug.print_debug("waiting for tree")
            sleep(30)
        end

        --dig tree trunk
        --spiral up then clear cut down (in case turtle gets stuck makes easier to rescue)
        local height = 0
        m.goForward(true)
        local moarTreeFlag = true
        while moarTreeFlag do
            m.goUp(true)
            moarTreeFlag = turtle.digUp()
            m.goForward(true)
            turtle.digUp()
            m.turnRight()
            height = height + 1
        end

        --one more loop to clear any remaining wood
        for i = 1, 4 do
            m.macroMove("UUFDR", false, true)
            height = height + 1
        end

        m.turnRight()
        for i = 1, height do
            m.macroMove("DFL", false, true)
        end
        
        for i = 1, 4 do
            m.goForward(true)
            turtle.digUp()
            m.turnLeft()
        end
        m.goHome()

        lib_debug.print_debug("Waiting for leaves to fall")
        sleep(180) --wait for leaves to fall

        --sweep area
        m.goUp(false)
        m.goForward(false)
        f.sweepUp(5)
        m.goBackwards(false)
        m.goDown(false)

        --plant saplings
        m.goUp(false)
        m.goForward(false)
        for i = 1, 4 do
            if itemTypes.selectSapling() then
                turtle.placeDown()
            else
                print("ran out of saplings")
                return
            end
            m.macroMove("FR",false,true)
        end

        m.goBackwards(false)
        m.goDown(false)

        f.dumpOther()
    end
end

--slots: crimson fungus, crimson nylium, bonemeal, charcoal
function mushroomTree()
    m.setTether(64)
    m.setHome()
    m.addBlacklist(itemTypes.noMine)
    while true do
        sleep(1)

        --place shroom down
        turtle.digDown()
        if not lib_inv_mgmt.selectWithRefill(1) then
            return
        end
        
        if not turtle.placeDown() then
            turtle.down()
            if not lib_inv_mgmt.selectWithRefill(2) then
                turtle.up()
                return
            end
            turtle.digDown()
            turtle.placeDown()
            turtle.up()
            goto continue
        end
        
        while not turtle.inspectUp() do
            if not lib_inv_mgmt.selectWithRefill(3) then
                return
            end
            turtle.placeDown()
        end

        turtle.digDown()
        
        m.goUp(true)
        for h = 1, 8 do
            if not lib_inv_mgmt.selectWithRefill(4) then
                return
            end
            if turtle.getFuelLevel() < 1000 then
                turtle.refuel()
            end

            local didSomething = m.spiralOut(3,digUpDown)
            if not didSomething then
                break
            end
            m.goUp(true)
            m.goUp(true)
            m.goUp(true)
        end
        m.goTo(0, 0, 0)
        lib_inv_mgmt.depositItems_Front(9)

        ::continue::
    end
    m.goTo(0, 0, 0)
end

function wheatFarm()
    while true do
        sleep(60)
        if f.isFullyGrownWheatBelow() then
            local transferResult = lib_inv_mgmt.transferInventory(5, "up", {"minecraft:wheat"}, true)
            if not transferResult then
                print("storage full")
                return
            end
            local didSomething = m.spiralOut(2,harvestWheat)

        end
    end
    
end

function harvestWheat()
    turtle.digDown()
    lib_inv_mgmt.selectWithRefill(5)
    turtle.placeDown()
end


function digUpDown()
    local result = false

    if m.canDig("up") and turtle.digUp() then
        result = true
    end
    
    if m.canDig("down") and turtle.digDown() then
        result = true
    end

    return result
end

-- Capture arguments passed to the script
local args = {...}

local arg1 = tonumber(args[1])

-- Check if all arguments were provided and are valid integers
if arg1 then
    if arg1 == 1 then
        oakFarm()
    elseif arg1 == 2 then
        megaSpruce()
    elseif arg1 == 3 then
        mushroomTree()
    elseif arg1 == 4 then
        wheatFarm()
    end
else
    tree = f.waitForTree()
    print("Tree found Mining!")
    if tree == "minecraft:spruce_log" then
        megaSpruce()
    else
        oakFarm()
    end
end