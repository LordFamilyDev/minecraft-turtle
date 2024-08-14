-- tSSH.lua

local lib_ssh = require("lib_ssh")

local args = {...}
if args[1] == "-v" then
    lib_ssh.verbose = true
    table.remove(args, 1)
end

if #args < 1 then
    print("Usage: tSSH [-v] <id>")
    return
end

local remoteId = tonumber(args[1])

if not lib_ssh.setupModem() then
    print("Failed to setup modem")
    return
end

print("Connecting to " .. remoteId)

local function executeRemote(command)
    lib_ssh.sendMessage(remoteId, {type="execute", command=command})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "result" then
        print(response.output)
    else
        print("No response or error occurred")
    end
end

local function listFiles()
    lib_ssh.sendMessage(remoteId, {type="ls"})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "ls_result" then
        for _, file in ipairs(response.files) do
            print(file)
        end
    else
        print("Failed to list files")
    end
end

local function changeDirectory(dir)
    lib_ssh.sendMessage(remoteId, {type="cd", dir=dir})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "cd_result" then
        print(response.message)
    else
        print("Failed to change directory")
    end
end

while true do
    write("> ")
    local input = read()
    if input == "exit" then
        break
    elseif input == "ls" then
        listFiles()
    elseif input:sub(1, 2) == "cd" then
        changeDirectory(input:sub(4))
    else
        executeRemote(input)
    end
end

print("Disconnected from " .. remoteId)