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
    if result == true then
        print("Program exited normally. Restarting in 5 seconds...")
    else
        print("Program crashed or exited abnormally. Restarting in 5 seconds...")
    end
    os.sleep(5)
end