m = require("/lib/move")
f = require("/lib/farming")

m.setHome()
f.waitForTree()
print("Tree found Mining!")
f.mineTree()
print("Going Home")
m.goHome()
