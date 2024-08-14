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
        else
            sendError(sender, "Unknown command type: " .. message.type)
        end
    elseif sender == nil and message == nil then
        print("No message received, continuing to listen...")
    else
        print("Unexpected receive result: " .. tostring(sender) .. ", " .. tostring(message))
    end
end