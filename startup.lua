local sPath = shell.path()
sPath = sPath .. ":/bin"
shell.setPath(sPath)
shell.run("/update")