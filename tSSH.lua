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
    local parts = {}
    for part in command:gmatch("%S+") do
        table.insert(parts, part)
    end
    local path = parts[1]
    table.remove(parts, 1)
    lib_ssh.sendMessage(remoteId, {type="execute", path=path, args=parts})
    
    local output = {}
    while true do
        local _, response = lib_ssh.receiveMessage(5)
        if response and response.type == "print" then
            print(response.output)
            table.insert(output, response.output)
        elseif response and response.type == "execute_result" then
            if response.output and #response.output > 0 and #output == 0 then
                print(response.output)
            end
            break
        elseif response and response.type == "error" then
            print("Error: " .. response.message)
            break
        elseif response == nil then
            print("No response or unexpected error occurred")
            break
        end
    end
end

local function listFiles()
    lib_ssh.sendMessage(remoteId, {type="ls"})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "ls_result" then
        print(response.files)
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

local function removeFile(path)
    lib_ssh.sendMessage(remoteId, {type="rm", path=path})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "rm_result" then
        print(response.message)
    elseif response and response.type == "error" then
        print("Error: " .. response.message)
    else
        print("Failed to remove file")
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
    elseif input:sub(1, 2) == "rm" then
        removeFile(input:sub(4))
    else
        executeRemote(input)
    end
end

print("Disconnected from " .. remoteId)