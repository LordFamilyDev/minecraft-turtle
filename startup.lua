local sPath = shell.path()
sPath = sPath .. ":/bin:/usr/bin"
shell.setPath(sPath)
shell.run("/update.lua")

if peripheral.find("modem") then
    shell.run("/bin/util/wrapper", "/usr/bin/vncd")
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
end

if fs.exists("/autorun.lua") then
    shell.run("/autorun.lua")
end