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

local originalPrint = _G.print

local function captureOutput(sender, func, ...)
    local capturedOutput = {}
    local customPrint = function(...)
        local args = {...}
        local line = table.concat(args, "\t")
        table.insert(capturedOutput, line)
        lib_ssh.sendMessage(sender, {type="print", output=line})
    end

    _G.print = customPrint
    local results = {pcall(func, ...)}
    _G.print = originalPrint

    if results[1] then
        table.remove(results, 1)
        return true, capturedOutput, results
    else
        return false, results[2]
    end
end

local function executeFile(sender, path, args)
    if not fs.exists(path) then
        return nil, "File not found: " .. path
    end

    if fs.isDir(path) then
        return nil, "Cannot execute a directory: " .. path
    end

    local func, err = loadfile(path)
    if not func then
        return nil, "Error loading file: " .. err
    end

    local oldEnv = getfenv(func)
    local newEnv = setmetatable({arg=args}, {__index=oldEnv})
    setfenv(func, newEnv)

    local ok, output, results = captureOutput(sender, func, table.unpack(args))
    
    if ok then
        if #output > 0 then
            return table.concat(output, "\n")
        else
            return table.concat(results, "\n")
        end
    else
        return nil, "Error executing file: " .. tostring(output)
    end
end

local function getFullPath(session, path)
    if path:sub(1, 1) == "/" then
        return fs.normalize(path)
    else
        return fs.normalize(fs.combine(session.cwd, path))
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

        if message.type == "write_file" then
            local fullPath = getFullPath(session, message.path)
            lib_ssh.print_debug("Attempting to write file: " .. fullPath)
            local file = fs.open(fullPath, "w")
            if file then
                file.write(message.content)
                file.close()
                lib_ssh.print_debug("File written successfully, sending confirmation")
                lib_ssh.sendMessage(sender, {type="file_written"})
            else
                sendError(sender, "Unable to create file: " .. fullPath)
            end
        elseif message.type == "read_file" then
            local fullPath = getFullPath(session, message.path)
            lib_ssh.print_debug("Attempting to read file: " .. fullPath)
            if fs.exists(fullPath) and not fs.isDir(fullPath) then
                local file = fs.open(fullPath, "r")
                if file then
                    local content = file.readAll()
                    file.close()
                    lib_ssh.print_debug("File read successfully, sending content")
                    lib_ssh.sendMessage(sender, {type="file_content", content=content})
                else
                    sendError(sender, "Unable to open file: " .. fullPath)
                end
            else
                sendError(sender, "File not found: " .. fullPath)
            end
        elseif message.type == "ls" then
            local fullPath = getFullPath(session, message.path or "")
            local files = fs.list(fullPath)
            lib_ssh.sendMessage(sender, {type="ls_result", files=files, path=fullPath})
        elseif message.type == "cd" then
            local newPath = getFullPath(session, message.dir)
            if fs.isDir(newPath) then
                session.cwd = newPath
                lib_ssh.print_debug("Changed directory, sending confirmation")
                lib_ssh.sendMessage(sender, {type="cd_result", message="Changed to " .. newPath, path=newPath})
            else
                sendError(sender, "Directory not found: " .. newPath)
            end
        elseif message.type == "rm" then
            local fullPath = getFullPath(session, message.path)
            if fs.exists(fullPath) then
                fs.delete(fullPath)
                lib_ssh.print_debug("File or directory deleted successfully")
                lib_ssh.sendMessage(sender, {type="rm_result", message="Deleted " .. fullPath})
            else
                sendError(sender, "File or directory not found: " .. fullPath)
            end
        elseif message.type == "mkdir" then
            local fullPath = getFullPath(session, message.path)
            if not fs.exists(fullPath) then
                fs.makeDir(fullPath)
                lib_ssh.print_debug("Directory created successfully")
                lib_ssh.sendMessage(sender, {type="mkdir_result", message="Created directory " .. fullPath})
            else
                sendError(sender, "Directory or file already exists: " .. fullPath)
            end
        elseif message.type == "execute" then
            local fullPath = getFullPath(session, message.path)
            local result, err = executeFile(sender, fullPath, message.args or {})
            if result then
                lib_ssh.sendMessage(sender, {type="execute_result", output=result})
            else
                sendError(sender, err)
            end
        elseif message.type == "pwd" then
            lib_ssh.print_debug("Sending current working directory")
            lib_ssh.sendMessage(sender, {type="pwd_result", path=session.cwd})
        else
            sendError(sender, "Unknown command type: " .. message.type)
        end
    elseif sender == nil and message == nil then
        -- No message received, continue listening
    else
        lib_ssh.print_debug("Unexpected receive result: " .. tostring(sender) .. ", " .. tostring(message))
    end
end