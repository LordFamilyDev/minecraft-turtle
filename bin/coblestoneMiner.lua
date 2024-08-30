itemTypes = require("/lib/item_types")

while true do
    ::continue::
    x, info = turtle.inspect()
    print("found:"..info.name)
    if itemTypes.isItemInList(info.name, {"stone"}) then
        turtle.dig()
    end
    turtle.select(1)
    if( turtle.getItemCount() == 64 ) then
        turtle.turnRight()
        turtle.turnRight()
        while not turtle.drop(64) do
            sleep(1)
        end
        turtle.turnRight()
        turtle.turnRight()
    end
    sleep(0.1)
end