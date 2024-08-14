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

local currentDir = "/"

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

local function listFiles(path)
    lib_ssh.sendMessage(remoteId, {type="ls", path=path})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "ls_result" then
        print("Contents of " .. response.path .. ":")
        if type(response.files) == "table" then
            for _, file in ipairs(response.files) do
                print(file)
            end
        else
            print("Unexpected ls result format")
        end
    else
        print("Failed to list files")
    end
end

local function changeDirectory(dir)
    lib_ssh.sendMessage(remoteId, {type="cd", dir=dir})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "cd_result" then
        currentDir = response.message:match("Changed to (.+)")
        print(response.message)
    else
        print("Failed to change directory")
    end
end

local function removeFileOrDirectory(path)
    lib_ssh.sendMessage(remoteId, {type="rm", path=path})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "rm_result" then
        print(response.message)
    elseif response and response.type == "error" then
        print("Error: " .. response.message)
    else
        print("Failed to remove file or directory")
    end
end

local function makeDirectory(path)
    lib_ssh.sendMessage(remoteId, {type="mkdir", path=path})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "mkdir_result" then
        print(response.message)
    elseif response and response.type == "error" then
        print("Error: " .. response.message)
    else
        print("Failed to create directory")
    end
end

local function printWorkingDirectory()
    lib_ssh.sendMessage(remoteId, {type="pwd"})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "pwd_result" then
        print(response.path)
    else
        print("Failed to get current working directory")
    end
end

while true do
    write(currentDir .. "> ")
    local input = read()
    if input == "exit" then
        break
    elseif input == "ls" then
        listFiles("")
    elseif input:sub(1, 3) == "ls " then
        listFiles(input:sub(4))
    elseif input:sub(1, 2) == "cd" then
        changeDirectory(input:sub(4))
    elseif input:sub(1, 2) == "rm" then
        removeFileOrDirectory(input:sub(4))
    elseif input:sub(1, 5) == "mkdir" then
        makeDirectory(input:sub(7))
    elseif input == "pwd" then
        printWorkingDirectory()
    else
        executeRemote(input)
    end
end

print("Disconnected from " .. remoteId)