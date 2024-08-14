-- tSCP.lua

local lib_ssh = require("lib_ssh")

local args = {...}
if #args < 2 then
    print("Usage: tSCP <src> <dest>")
    return
end

if not lib_ssh.setupModem() then
    print("Failed to setup modem")
    return
end

local function parseAddress(addr)
    local id, path = addr:match("(%d+):(.+)")
    if id then
        return tonumber(id), path
    else
        return nil, addr
    end
end

local srcId, srcPath = parseAddress(args[1])
local destId, destPath = parseAddress(args[2])

local function readFile(path)
    local file = fs.open(path, "r")
    if not file then
        return nil, "Unable to open file"
    end
    local content = file.readAll()
    file.close()
    return content
end

local function writeFile(path, content)
    local file = fs.open(path, "w")
    if not file then
        return false, "Unable to create file"
    end
    file.write(content)
    file.close()
    return true
end

if srcId then
    -- Remote to local
    lib_ssh.sendMessage(srcId, {type="read_file", path=srcPath})
    local _, response = lib_ssh.receiveMessage(5)
    if response and response.type == "file_content" then
        local success, err = writeFile(destPath, response.content)
        if success then
            print("File transferred successfully")
        else
            print("Error writing file: " .. err)
        end
    else
        print("Error reading remote file")
    end
elseif destId then
    -- Local to remote
    local content, err = readFile(srcPath)
    if content then
        lib_ssh.sendMessage(destId, {type="write_file", path=destPath, content=content})
        local _, response = lib_ssh.receiveMessage(5)
        if response and response.type == "file_written" then
            print("File transferred successfully")
        else
            print("Error writing remote file")
        end
    else
        print("Error reading local file: " .. err)
    end
else
    print("Invalid source or destination")
end