--[[
    Turtle Control Script
    ---------------------
    This script allows you to control a turtle to perform various tasks such as digging, placing blocks, and refueling.
    
    Usage:
    - command: The action to perform. Options are "dig", "place", and "refuel".
    - x, y, z: The dimensions of the area to operate in (required for "dig" and "place").
    - item: The item to place (required for "place" command).
    
    Default Values:
    - command: "straight"
    - x, y, z: 10 (Default size for cube)
    - item: "minecraft:dirt" (Default item to place)
    
    Example:
    - To dig a 10x10x10 cube: `turtleScript dig 10 10 10`
    - To place blocks in a 5x5x5 cube using dirt: `turtleScript place 5 5 5 minecraft:dirt`
    - To refuel the turtle with up to 100 units of fuel: `turtleScript refuel 100`
--]]

-- Function to display help information
local function displayHelp()
    print("Turtle Control Script Help")
    print("----------------------------")
    print("Usage:")
    print("  command: The action to perform. Options are 'dig', 'place', 'refuel'.")
    print("  x, y, z: The dimensions of the area to operate in (required for 'dig' and 'place').")
    print("  item: The item to place (required for 'place' command).")
    print()
    print("Default Values:")
    print("  command: 'straight'")
    print("  x, y, z: 10 (Default size for cube)")
    print("  item: 'minecraft:dirt' (Default item to place)")
    print()
    print("Examples:")
    print("  turtleScript dig 10 10 10")
    print("  turtleScript place 5 5 5 minecraft:dirt")
    print("  turtleScript refuel 100")
end

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
local function main(command, x, y, z, item)
    if command == "dig" then
        doCube(x, y, z, true, safeDig)
    -- elseif command == "mine" then
    --     bin_boring.bore(x)
    elseif command == "place" then
        doCube(x, y, z, false, place)
    elseif command == "refuel" then
        refuel(x)
    elseif command == "help" then
        displayHelp()
    else
        print("Invalid command. Type 'help' for usage instructions.")
    end
end

-- Get the command-line arguments
local args = {
    command = arg[1],
    x = arg[2],
    y = arg[3],
    z = arg[4],
    item = arg[5]
}

-- Validate the arguments
if args.command == nil then
    print("Invalid or no command provided. Defaulting to 'dig'.")
    args.command = "straight"
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
    print("No item. Defaulting item to 'minecraft:dirt'.")
    args.item = "minecraft:dirt"
end

main(args.command, args.x, args.y, args.z, args.item)
