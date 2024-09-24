local sPath = shell.path()
sPath = sPath .. ":/bin:/usr/bin"
shell.setPath(sPath)
shell.run("/update.lua")


local autorun = true
-- Giving a turtle an achillies heel of a wooden pickaxe
if turtle then
    x = turtle.getItemDetail(1)
    if x and x.name == "minecraft:wooden_pickaxe" then
        print("AAAHHH A wooden Pickaxe!!! STOPPNG!!")
        autorun = false
    end
end


-- NOTE:  wrapper does not return
if peripheral.find("modem") then
    if autorun and fs.exists("/autorun.lua") then
        shell.run("/bin/util/wrapper", "/usr/bin/vncd", "/autorun.lua")
        return
    else
        shell.run("/bin/util/wrapper", "/usr/bin/vncd")
        return
    end
else
    -- clear the screen
    term.clear()
    term.setCursorPos(1, 1)
    -- Print "CraftOS 1.9" in yellow
    term.setTextColor(colors.yellow)
    print("CraftOS 1.9 (no network)")
    -- set the text color to white
    term.setTextColor(colors.white)
    -- run motd command
    shell.run("/rom/programs/motd.lua")

    if autorun and fs.exists("/autorun.lua") then
        shell.run("/autorun.lua")
    end
end

