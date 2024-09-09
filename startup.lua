local sPath = shell.path()
sPath = sPath .. ":/bin"
shell.setPath(sPath)
shell.run("/bin/update")

-- Startup Remote Desktop Service
if term.isColor() then
    -- this is an advanced computer
    if fs.exists("/usr/bin/vncd") then
        if fs.exists("/usr/bin/util/wrapper") then
            shell.run("background", "/bin/util/wrapper", "/usr/bin/vncd")
        end
    end
end