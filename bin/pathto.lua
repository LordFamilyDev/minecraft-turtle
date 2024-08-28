m = require("/lib/move")

args = {...}
x = tonumber(args[1])
z = tonumber(args[2])
d = tonumber(args[3])

m.setHome()
m.pathTo(x,z,d)