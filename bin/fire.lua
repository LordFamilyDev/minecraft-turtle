-- Function to perform the downwards mining pattern
local function mineDown(x)
    for i = 1, x do
        -- Mine down
        turtle.digDown()
        turtle.down()

        -- Dig a 3x3 area down
        for j = 1, 4 do
            for k = 1, 2 do
                turtle.dig()
                turtle.forward()
            end

            turtle.turnRight()

        end
    end
end

-- Function to perform the straight mining pattern
local function mineStraight(x)
    for i = 1, x do
        turtle.dig()
        turtle.digDown()
        turtle.forward()
    end
end

-- Mine Cube
local function mineCube(x, y, z)
    local turnRight = true
    for k = 1, z do
        for j = 1, y do
            for i = 1, x do
                turtle.dig()
                turtle.forward()
            end
            -- skip last y
            if j ~= y then
                if turnRight then
                    turtle.turnRight();
                    turtle.dig();
                    turtle.forward()
                    turtle.turnRight()   
                else
                    turtle.turnLeft();
                    turtle.dig();
                    turtle.forward()
                    turtle.turnLeft()   
                end 
                turnRight = not turnRight
            end
        end
        -- skip turn last z
        if k ~= z  then            
            turtle.digDown()
            turtle.down();
            turtle.turnRight();
            turtle.turnRight();
        end
    end
end


-- Main function to select pattern based on arguments
local function main(direction, x, y, z)
    if direction == "down" then
        mineDown(x)
    elseif direction == "straight" then
        mineStraight(x)
    elseif direction == "cube" then
        mineCube(x, y, z)
    else
        print("Invalid direction.")
    end
end

-- Get the command-line arguments
local args = {
    direction = arg[1],
    x = arg[2],
    y = arg[3],
    z = arg[4]
}

-- Validate the arguments
if args.direction == nil then
    print("Invalid or no direction provided. Defaulting to 'straight'.")
    args.direction = "straight"
end
if not tonumber(args.x) then
    print("Invalid input or no input provided. Defaulting to 10.")
    args.x = 10 -- Default value
else
    args.x = tonumber(args.x)
end
if not tonumber(args.y) then
    print("Invalid input or no input provided. Defaulting to 10.")
    args.y = 10 -- Default value
else
    args.y = tonumber(args.y)
end
if not tonumber(args.z) then
    print("Invalid input or no input provided. Defaulting to 10.")
    args.z = 10 -- Default value
else
    args.z = tonumber(args.z)
end

main(args.direction, args.x, args.y, args.z)
