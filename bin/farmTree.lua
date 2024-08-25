m = require("/lib/move")
f = require("/lib/farming")
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
