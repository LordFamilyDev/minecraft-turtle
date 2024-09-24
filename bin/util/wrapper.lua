-- wrapper.lua (/usr/bin/wrapper)
-- a wrapper script that restarts a program if it crashes or exits abnormally

-- shell.run("background", "/bin/util/wrapper", "/usr/bin/vncd")
-- shell.run("background", "/bin/util/wrapper", "/bin/util/blockd")
-- shell.run("background", "/bin/util/wrapper", "gps", "host", 0, 311, 0)

local args = {...}
if #args == 0 then
    print("Usage: wrapper <program> [arg1] [arg2] ...")
    return
end

local program = args[1]
local programArgs = {table.unpack(args, 2)}

local function runProgram()
    print("Starting program: " .. program)
    local result = shell.run(program, table.unpack(programArgs))
    print("Program exited with result: " .. tostring(result))
    return result
end

print("Wrapper started for program: " .. program)

while true do
    local result = runProgram()
    os.sleep()
    -- Giving a turtle an achillies heel of a wooden pickaxe
    if turtle then
        x = turtle.getItemDetail(1)
        if x and x.name == "minecraft:wooden_pickaxe" then
            print("AAAHHH A wooden Pickaxe!!! STOPPNG!!")
            return
        end
    end
end