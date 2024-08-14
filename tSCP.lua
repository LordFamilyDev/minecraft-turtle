-- tSCP.lua

local lib_ssh = require("lib_ssh")

local args = {...}
if #args < 2 then
    print("Usage: tSCP <src> <dest>")
    print("Example: tSCP foo.lua 1: or tSCP 1:foo.lua ./")
    return
end

if not lib_ssh.setupModem() then
    print("Failed to setup modem")
    return
end

local function parseAddress(addr)
    local id, path = addr:match("(%d+):(.*)")
    if id then
        return tonumber(id), path
    else
        return nil, addr
    end
end

local function getFilename(path)
    return path:match("([^/\\]+)$")
end

local function joinPath(dir, file)
    if dir == "" or dir == "." or dir == "./" then
        return file
    else
        return fs.combine(dir, file)
    end
end

local srcId, srcPath = parseAddress(args[1])
local destId, destPath = parseAddress(args[2])

-- Determine the actual destination path
local actualDestPath
if destId then
    -- Remote destination
    actualDestPath = destPath ~= "" and destPath or getFilename(srcPath)
else
    -- Local destination
    if destPath == "" or destPath == "." or destPath == "./" then
        actualDestPath = getFilename(srcPath)
    else
        actualDestPath = joinPath(destPath, getFilename(srcPath))
    end
end

print("Source:", srcId and ("Remote " .. srcId .. ":" .. srcPath) or srcPath)
print("Destination:", destId and ("Remote " .. destId .. ":" .. actualDestPath) or actualDestPath)

local function readFile(path)
    local file = fs.open(path, "r")
    if not file then
        return nil, "Unable to open file: " .. path
    end
    local content = file.readAll()
    file.close()
    return content
end

local function writeFile(path, content)
    local file = fs.open(path, "w")
    if not file then
        return false, "Unable to create file: " .. path
    end
    file.write(content)
    file.close()
    return true
end

if srcId then
    -- Remote to local
    print("Requesting file from remote...")
    lib_ssh.sendMessage(srcId, {type="read_file", path=srcPath})
    local sender, response = lib_ssh.receiveMessage(10)  -- Increased timeout
    print("Received response from: " .. tostring(sender))
    print("Response type: " .. (response and response.type or "nil"))
    if sender == srcId and response and response.type == "file_content" then
        local success, err = writeFile(actualDestPath, response.content)
        if success then
            print("File transferred successfully")
        else
            print("Error writing file: " .. err)
        end
    elseif sender == srcId and response and response.type == "error" then
        print("Error reading remote file: " .. response.message)
    else
        print("Error: No response or unexpected response from remote")
        print("Sender: " .. tostring(sender) .. ", Expected: " .. tostring(srcId))
        print("Response: " .. textutils.serialize(response))
    end
elseif destId then
    -- Local to remote
    local content, err = readFile(srcPath)
    if content then
        print("Sending file to remote...")
        lib_ssh.sendMessage(destId, {type="write_file", path=actualDestPath, content=content})
        local sender, response = lib_ssh.receiveMessage(10)  -- Increased timeout
        print("Received response from: " .. tostring(sender))
        print("Response type: " .. (response and response.type or "nil"))
        if sender == destId and response and response.type == "file_written" then
            print("File transferred successfully")
        elseif sender == destId and response and response.type == "error" then
            print("Error writing remote file: " .. response.message)
        else
            print("Error: No response or unexpected response from remote")
            print("Sender: " .. tostring(sender) .. ", Expected: " .. tostring(destId))
            print("Response: " .. textutils.serialize(response))
        end
    else
        print("Error reading local file: " .. err)
    end
else
    print("Invalid source or destination")
end