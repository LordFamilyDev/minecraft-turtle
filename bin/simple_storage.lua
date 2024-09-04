lib_ss = require("/lib/lib_user_storage")

-- Capture arguments passed to the script
local args = {...}

--initializeStorage()

if args[1] == nil or args[1] == "help" then
    print("usage:")
    print("get [partial or complete blockName] [quantity]")
    print("clear")
    print("initialize [clientChestName]")
    print("capacity")
    print("test")
elseif args[1] == "get" then
    if lib_ss.userChest == nil then
        print("initialize storage system before using")
    end
    if args[3] == nil then
        args[3] = 1
    end
    lib_ss.requestMaterial(args[2], tonumber(args[3]))
elseif args[1] == "clear" then
    if lib_ss.userChest == nil then
        print("initialize storage system before using")
    end
    lib_ss.clearUserStorage()
elseif args[1] == "initialize" then
    --verify that args[2] is a chest in the network and save it to file locally
    lib_ss.writeClientChestName(args[2])
elseif args[1] == "capacity" then
    local used, total = lib_ss.getStorageUtilization()
    print("Network capacity: " .. used .. " / " .. total)
elseif args[1] == "test" then
    lib_ss.inventoryTimeTest()
end
