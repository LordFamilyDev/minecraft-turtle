local sPath = shell.path()
sPath = sPath .. ":/bin:/usr/bin"
shell.setPath(sPath)
os.run({}, "/httpupdate.lua")

-- Clear the screen
term.clear()
term.setCursorPos(1,1)
-- Print "CraftOS 1.9" in yellow
term.setTextColor(colors.yellow)
print("CraftOS 1.9 (updated)")
term.setTextColor(colors.white)
shell.run("motd")

-- Startup Remote Desktop Service
if term.isColor() then
    -- check for updates
    -- this is an advanced computer
    if fs.exists("/usr/bin/vncd") then
        if fs.exists("/bin/util/wrapper.lua") then
            -- check if modem exists
            if peripheral.find("modem") then
                shell.run("background", "/bin/util/wrapper", "/usr/bin/vncd")
            end
        end
    end
end
