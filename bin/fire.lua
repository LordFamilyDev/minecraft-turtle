-- ToDo add header

-- select item
local function selectItem(itemName)
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == itemName then
            turtle.select(i)
            return true
        end
    end
    return false
end

-- Refuel
local function refuel(x)

    hasBucket = selectItem("minecraft:bucket")
    if not hasBucket then
        print("no bucket of fuckets")
        return false
    end


    for i = 1, x do

        -- Check if fuel is already at maximum
        if turtle.getFuelLevel() >= turtle.getFuelLimit() then
            print("Fuel is already at maximum. Stopping refuel process.")
            x = i  -- Set x to the current position
            break  -- Break out of the for loop
        end

        -- Move
        turtle.dig()
        if not turtle.forward() then
            print("Unable to move forward. Obstacle detected.")
            return false
        end

        -- Check the block below for lava
        local success, block = turtle.inspectDown()
        if success and block.name == "minecraft:lava" then
            if selectItem("minecraft:bucket") then
                turtle.placeDown()  -- Use the bucket to scoop the lava
                turtle.refuel()     -- Refuel using the lava bucket
                print("Refueled using lava at position " .. i)
            else
                print("No empty bucket found. Cannot refuel.")
                return false
            end
        end
    end
    -- Turn around
    turtle.turnLeft()
    turtle.turnLeft()

    -- Move back to the original position
    for i = 1, x do
        if not turtle.forward() then
            print("Unable to move back. Obstacle detected.")
            return false
        end
    end

    -- Turn back to original direction
    turtle.turnLeft()
    turtle.turnLeft()

    print("Refuel process complete and returned to the original position.")
    return true
end


-- Place Function
local function place()
    local selectedItemDetail = turtle.getItemDetail()
    -- item = args.item
    item = "minecraft:dirt"

    if not selectedItemDetail or selectedItemDetail.name ~= item then
        if not selectItem(item) then
            print("Item not found in inventory: " .. item)
            return false
        end
    end
    
    return turtle.placeDown()
end

-- safeDig
local function safeDig()
    local attempts = 0
    local maxAttempts = 10
    
    while turtle.detect() and attempts < maxAttempts do
        turtle.dig()
        attempts = attempts + 1
    end
end

-- doCube
local function doCube(x, y, z, goDown, action)
    local turnRight = true
    for k = 1, z do
        for j = 1, y do
            for i = 1, x do
                action()
                turtle.forward()
            end
            -- skip last y
            if j ~= y then
                if turnRight then
                    turtle.turnRight();
                    action()
                    turtle.forward()
                    turtle.turnRight()   
                else
                    turtle.turnLeft();
                    action()
                    turtle.forward()
                    turtle.turnLeft()   
                end 
                turnRight = not turnRight
            end
        end
        -- skip turn last z
        if k ~= z  then
            if goDown then            
                turtle.digDown()
                turtle.down();
            else
                turtle.up();
            end
            turtle.turnRight();
            turtle.turnRight();
        end
    end

    -- Return to the original position and orientation
    -- Move back to the original x position
    if turnRight then
        turtle.turnRight()
        turtle.turnRight()
        for i = 1, x - 1 do
            turtle.forward()
        end
    end

    -- Move back to the original y position
    turtle.turnRight()
    for j = 1, y - 1 do
        turtle.forward()
    end
    turtle.turnRight()

    -- Move back up to the original z level
    for k = 1, z - 1 do
        if goDown then
            turtle.up()
        else
            turtle.down()
        end
    end

end


-- Main function to select pattern based on arguments
local function main(direction, x, y, z, item)
    if direction == "down" then
        mineDown(x)
    elseif direction == "straight" then
        mineStraight(x)
    elseif direction == "cubeDig" then
        doCube(x, y, z, true, safeDig)
    elseif direction == "cubePlace" then
        doCube(x, y, z, false, place)
    elseif direction == "refuel" then
        refuel(x)
    else
        print("Invalid direction.")
    end
end

-- Get the command-line arguments
local args = {
    direction = arg[1],
    x = arg[2],
    y = arg[3],
    z = arg[4],
    item = arg[5]
}

-- Validate the arguments
if args.direction == nil then
    print("Invalid or no direction provided. Defaulting to 'straight'.")
    args.direction = "straight"
end
if not tonumber(args.x) then
    print("No x. Defaulting to 10.")
    args.x = 10 -- Default value
else
    args.x = tonumber(args.x)
end
if not tonumber(args.y) then
    print("No y. Defaulting to 10.")
    args.y = 10 -- Default value
else
    args.y = tonumber(args.y)
end
if not tonumber(args.z) then
    print("No z. Defaulting to 10.")
    args.z = 10 -- Default value
else
    args.z = tonumber(args.z)
end
if args.item == nil then
    print("Invalid or no item provided. Defaulting to 'minecraft:dirt'.")
    args.item = "minecraft:dirt"
end

main(args.direction, args.x, args.y, args.z, args.item)
