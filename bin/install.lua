-- install.lua
local args = {...}
local AUTORUN = "/autorun.lua"


local function readStartup()
    if not fs.exists(AUTORUN) then
        return {}
    end
    local file = fs.open(AUTORUN, "r")
    local lines = {}
    for line in file.readLine do
        lines[#lines + 1] = line
    end
    file.close()
    return lines
end

local function writeStartup(lines)
    local file = fs.open(AUTORUN, "w")
    for _, line in ipairs(lines) do
        file.writeLine(line)
    end
    file.close()
end

local function install(program, ...)
    local lines = readStartup()
    local argStr = table.concat({...}, " ")
    if #{...} > 0  then
        print("Found lines in argstr"..#{...})
        lines[#lines + 1] = string.format('shell.run("/bin/%s %s")', program, argStr)
    else
        lines[#lines + 1] = string.format('shell.run("/bin/%s")', program)
    end
    writeStartup(lines)
    print(string.format("Installed %s to autorun", program))
end

local function remove(program)
    local lines = readStartup()
    local removed = false
    for i = #lines, 1, -1 do
        if lines[i]:match(string.format('shell%%.run%%("/bin/%s".', program)) then
            table.remove(lines, i)
            removed = true
        end
    end
    if removed then
        writeStartup(lines)
        print(string.format("Removed %s from autorun", program))
    else
        print(string.format("%s was not in autorun", program))
    end
end

if #args < 1 then
    print("Usage: install <program> [args...] or install -r <program>")
    return
end

if args[1] == "-r" then
    if #args < 2 then
        print("Usage: install -r <program>")
        return
    end
    remove(args[2])
else
    install(table.unpack(args))
end