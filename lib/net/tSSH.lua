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

local function receiveResponse(expectedType)
    lib_ssh.print_debug("Waiting for response...")
    local sender, response = lib_ssh.receiveMessage(5)
    lib_ssh.print_debug("Received response from: " .. tostring(sender))
    lib_ssh.print_debug("Response: " .. textutils.serialize(response))
    if sender ~= remoteId then
        print("Received response from unexpected sender: " .. tostring(sender))
        return nil
    end
    if not response then
        print("No response received")
        return nil
    end
    if response.type == "error" then
        print("Error: " .. response.message)
        return nil
    end
    if expectedType and response.type ~= expectedType then
        print("Unexpected response type: " .. response.type)
        return nil
    end
    return response
end

local function listFiles(path)
    lib_ssh.sendMessage(remoteId, {type="ls", path=path})
    local response = receiveResponse("ls_result")
    if response then
        print("Contents of " .. response.path .. ":")
        if type(response.files) == "table" then
            for _, file in ipairs(response.files) do
                print(file)
            end
        else
            print("Unexpected ls result format")
        end
    end
end

local function changeDirectory(dir)
    lib_ssh.sendMessage(remoteId, {type="cd", dir=dir})
    local response = receiveResponse("cd_result")
    if response then
        currentDir = response.path
        print(response.message)
    end
end

local function removeFileOrDirectory(path)
    lib_ssh.sendMessage(remoteId, {type="rm", path=path})
    local response = receiveResponse("rm_result")
    if response then
        print(response.message)
    end
end

local function makeDirectory(path)
    lib_ssh.sendMessage(remoteId, {type="mkdir", path=path})
    local response = receiveResponse("mkdir_result")
    if response then
        print(response.message)
    end
end

local function printWorkingDirectory()
    lib_ssh.sendMessage(remoteId, {type="pwd"})
    local response = receiveResponse("pwd_result")
    if response then
        currentDir = response.path
        print("Current working directory: " .. currentDir)
    end
end

local function executeRemote(command)
    local parts = {}
    for part in command:gmatch("%S+") do
        table.insert(parts, part)
    end
    local path = parts[1]
    table.remove(parts, 1)
    lib_ssh.sendMessage(remoteId, {type="execute", path=path, args=parts})
    
    local hadOutput = false
    while true do
        local response = receiveResponse()
        if not response then
            print("No response received")
            break
        elseif response.type == "print" then
            print(response.output)
            hadOutput = true
        elseif response.type == "execute_result" then
            break
        elseif response.type == "error" then
            print("Error: " .. response.message)
            break
        else
            print("Unexpected response type: " .. response.type)
            break
        end
    end
    if not hadOutput then
        print("Command executed successfully (no output)")
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