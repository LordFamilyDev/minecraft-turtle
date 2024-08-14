-- tSSHd.lua

local lib_ssh = require("lib_ssh")

print("tSSHd starting...")

if not lib_ssh.setupModem() then
    print("Failed to setup modem")
    return
end

print("SSH daemon started. Computer ID: " .. os.getComputerID())
print("Waiting for connections...")

local function sendError(sender, message)
    print("Sending error to " .. sender .. ": " .. message)
    lib_ssh.sendMessage(sender, {type="error", message=message})
end

while true do
    local sender, message = lib_ssh.receiveMessage(5)  -- Add a timeout
    if sender and message then
        print("Received message from " .. sender .. ": " .. textutils.serialize(message))
        
        if message.type == "write_file" then
            print("Attempting to write file: " .. message.path)
            local file = fs.open(message.path, "w")
            if file then
                file.write(message.content)
                file.close()
                print("File written successfully, sending confirmation")
                lib_ssh.sendMessage(sender, {type="file_written"})
            else
                sendError(sender, "Unable to create file: " .. message.path)
            end
        elseif message.type == "read_file" then
            print("Attempting to read file: " .. message.path)
            if fs.exists(message.path) and not fs.isDir(message.path) then
                local file = fs.open(message.path, "r")
                if file then
                    local content = file.readAll()
                    file.close()
                    print("File read successfully, sending content")
                    lib_ssh.sendMessage(sender, {type="file_content", content=content})
                else
                    sendError(sender, "Unable to open file: " .. message.path)
                end
            else
                sendError(sender, "File not found: " .. message.path)
            end
        elseif message.type == "ls" then
            local files = fs.list(".")
            print("Sending ls result")
            lib_ssh.sendMessage(sender, {type="ls_result", files=files})
        elseif message.type == "cd" then
            if fs.isDir(message.dir) then
                shell.setDir(message.dir)
                print("Changed directory, sending confirmation")
                lib_ssh.sendMessage(sender, {type="cd_result", message="Changed to " .. message.dir})
            else
                sendError(sender, "Directory not found: " .. message.dir)
            end
        else
            sendError(sender, "Unknown command type: " .. message.type)
        end
    elseif sender == nil and message == nil then
        -- No message received, continue listening
    else
        print("Unexpected receive result: " .. tostring(sender) .. ", " .. tostring(message))
    end
end