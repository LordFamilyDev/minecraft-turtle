m = require("/lib/move")

args = {...}

for i = 1, #args do
    if args[i] == "--relPos" then
        x, z, d = m.getPos()
        xd,zd = m.getDir()
        print("I'm Here:" .. x .. ":" .. z ..":" .. d, " Facing:"..xd..":"..zd)
    end
end