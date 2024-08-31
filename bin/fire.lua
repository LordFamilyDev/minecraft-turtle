
-- Function to perform the mining pattern
local function minePattern()
    -- Mine down
    turtle.digDown()
    turtle.down()

    -- Mine forward
    turtle.dig()
    turtle.forward()

    -- Turn Around
    turtle.turnRight()
    turtle.turnRight()

end

-- Main function to execute the pattern `x` times
local function main(x)
    for i = 1, x do
        minePattern()
    end
end

-- Get the number of times to run the loop from the command-line argument or default to 10
local x = tonumber(...)

if x == nil or x <= 0 then
    x = 10 -- Default value
end

print("Mining pattern will run " .. x .. " times.")
main(x)
