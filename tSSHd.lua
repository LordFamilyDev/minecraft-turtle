-- tSSHd.lua

local lib_ssh = require("lib_ssh")

local args = {...}
if args[1] == "-v" then
    lib_ssh.verbose = true
end

lib_ssh.print_debug("tSSHd starting...")

if not lib_ssh.setupModem() then
    print("Failed to setup modem")
    return
end

print("SSH daemon started. Computer ID: " .. os.getComputerID())
lib_ssh.print_debug("Waiting for connections...")

local sessions = {}

local function sendError(sender, message)
    lib_ssh.print_debug("Sending error to " .. sender .. ": " .. message)
    lib_ssh.sendMessage(sender, {type="error", message=message})
end

local function getFullPath(session, path)
    if path:sub(1, 1) == "/" then
        return fs.combine("/", path)
    else
        return fs.combine(session.cwd, path)
    end
end

while true do
    local sender, message = lib_ssh.receiveMessage(5)  -- Add a timeout
    if sender and message then
        lib_ssh.print_debug("Received message from " .. sender .. ": " .. textutils.serialize(message))
        
        if not sessions[sender] then
            sessions[sender] = {cwd = "/"}
        end
        local session = sessions[sender]

        if message.type == "ls" then
            local fullPath = getFullPath(session, message.path or "")
            local success, result = pcall(fs.list, fullPath)
            if success then
                lib_ssh.sendMessage(sender, {type="ls_result", files=result, path=fullPath})
            else
                sendError(sender, "Failed to list files: " .. tostring(result))
            end
        elseif message.type == "cd" then
            local newPath = getFullPath(session, message.dir)
            if fs.isDir(newPath) then
                session.cwd = newPath
                lib_ssh.print_debug("Changed directory, sending confirmation")
                lib_ssh.sendMessage(sender, {type="cd_result", message="Changed to " .. newPath, path=newPath})
            else
                sendError(sender, "Directory not found: " .. newPath)
            end
        elseif message.type == "pwd" then
            lib_ssh.print_debug("Sending current working directory")
            lib_ssh.sendMessage(sender, {type="pwd_result", path=session.cwd})
        elseif message.type == "mkdir" then
            local fullPath = getFullPath(session, message.path)
            local success, result = pcall(fs.makeDir, fullPath)
            if success then
                lib_ssh.print_debug("Directory created successfully")
                lib_ssh.sendMessage(sender, {type="mkdir_result", message="Created directory " .. fullPath})
            else
                sendError(sender, "Failed to create directory: " .. tostring(result))
            end
        elseif message.type == "rm" then
            local fullPath = getFullPath(session, message.path)
            local success, result = pcall(fs.delete, fullPath)
            if success then
                lib_ssh.print_debug("File or directory deleted successfully")
                lib_ssh.sendMessage(sender, {type="rm_result", message="Deleted " .. fullPath})
            else
                sendError(sender, "Failed to delete: " .. tostring(result))
            end
        else
            sendError(sender, "Unknown command type: " .. message.type)
        end
    elseif sender == nil and message == nil then
        -- No message received, continue listening
    else
        lib_ssh.print_debug("Unexpected receive result: " .. tostring(sender) .. ", " .. tostring(message))
    end
end