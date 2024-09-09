local sPath = shell.path()
sPath = sPath .. ":/bin"
shell.setPath(sPath)

-- Startup Remote Desktop Service
if term.isColor() then
    -- check for updates
    shell.run("background", "httpupdate")
    -- this is an advanced computer
    if fs.exists("/usr/bin/vncd") then
        if fs.exists("/bin/util/wrapper.lua") then
            -- check if modem exists
            if peripheral.find("modem") then
                shell.run("background", "/bin/util/wrapper", "/usr/bin/vncd")
            end
        end
    end
else
    shell.run("httpupdate")
end