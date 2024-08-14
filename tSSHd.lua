-- tSSHd.lua

local lib_ssh = require("lib_ssh")

if not lib_ssh.setupModem() then
    print("Failed to setup modem")
    return
end

print("SSH daemon started. Waiting for connections...")

while true do
    local sender, message = lib_ssh.receiveMessage()
    if sender and message then
        if message.type == "execute" then
            local func, err = load(message.command)
            if func then
                local ok, result = pcall(func)
                if ok then
                    lib_ssh.sendMessage(sender, {type="result", output=tostring(result)})
                else
                    lib_ssh.sendMessage(sender, {type="result", output="Error: " .. tostring(result)})
                end
            else
                lib_ssh.sendMessage(sender, {type="result", output="Error: " .. tostring(err)})
            end
        elseif message.type == "ls" then
            local files = fs.list(".")
            lib_ssh.sendMessage(sender, {type="ls_result", files=files})
        elseif message.type == "cd" then
            if fs.isDir(message.dir) then
                shell.setDir(message.dir)
                lib_ssh.sendMessage(sender, {type="cd_result", message="Changed to " .. message.dir})
            else
                lib_ssh.sendMessage(sender, {type="cd_result", message="Directory not found: " .. message.dir})
            end
        end
    end
end