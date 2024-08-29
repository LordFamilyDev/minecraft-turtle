storageLib = require("/lib/storage")

args = {...}

for i = 1, #args do
    if args[i] == "--get" then
        storageLib.getItem(args[i+1])
    elseif args[i] == "--put" then
        storageLib.pushItem(args[i+1])
    end
end