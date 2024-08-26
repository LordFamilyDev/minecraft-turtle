m = require("/lib/move")
f = require("/lib/farming")
local itemTypes = require("/lib/item_types")


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
    while true do
        m.setHome()
        ::continue::
        f.waitForTree()
        print("Tree found Mining!")
        f.mineTree()
        print("Get the leaves")
        f.mineLeaves()
        print("Feed the furnace")
        m.goTo(0,0,2,1,0) --above the furnace
        f.fillFurnace("Down")
        if f.isTree() then
            goto continue
        end
        m.goForward(true)
        m.goDown(true)
        m.turnRight()
        m.turnRight()
        f.fillFurnace("Forward")
        m.goDown(true)
        m.goForward(true)
        turtle.suckUp()
        m.goTo(2,2,0,1,0)
        f.dumpWood()
        m.goTo(2,-2,0,1,0)
        f.dumpCharcoal()
        m.goTo(-2,2,0,1,0)
        f.dumpOther()
        print("Sweep up")
        f.sweepUp()
        print("Going Home")
        m.goHome()
        sleep(0.5)
    end
end

function megaSpruce()
    m.setHome()
    --turtle facing left sapling with chest under the turtle
    while true do
        while not f.isTree() do
            sleep(30)
        end

        --dig tree trunk
        --spiral up then clear cut down (in case turtle gets stuck makes easier to rescue)
        height = 0
        m.goForward(true)
        while itemTypes.isTreeUp() do
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

        --plant saplings
        m.goUp(true)
        m.goForward(true)
        for i = 1, 4 do
            if itemTypes.selectSapling() then
                turtle.placeDown()
            else
                print("ran out of saplings")
                return
            end
            m.macroMove("FR",false,true)
        end

        turtle.back()
        turtle.down()

        sleep(180) --wait for leaves to fall

        --sweep area
        turtle.up()
        f.sweepUp(4)

        turtle.down()

        f.dumpOther()
    end
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
    end
else
    print("Please provide valid arguments:")
    print("1: oak farmer")
    print("2: megaSpruce farmer")
end
