s = require("/lib/storage")
inv = require("lib/lib_inv_mgmt")

local args = {...}
local chestNum = tonumber(args[1])
local chestName = "minecraft:chest_" .. chestNum

while true do
    if redstone.getInput("front") then
        turtle.suck()
        s.pushItems("all")
        turtle.attack()
        turtle.attack()
        turtle.attack()
        turtle.suck()
        local slot = inv.selectItem("minecraft:chest_minecart")
        if slot ~= nil then
            turtle.select(slot)
            turtle.dropDown
        end
    end
end