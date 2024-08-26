-- lib_ssh.lua

local lib_ssh = {}

-- Global verbose flag
lib_ssh.verbose = false

-- Debug print function
function lib_ssh.print_debug(...)
    if lib_ssh.verbose then
        print(...)
    end
end

-- Function to find and use the modem
function lib_ssh.setupModem()
    local sides = {"left", "right", "back"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
            lib_ssh.print_debug("Modem found and opened on " .. side)
            return true
        end
    end
    
    -- If modem not equipped, check inventory and equip if found
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "computercraft:wireless_modem" then
            turtle.select(slot)
            for _, side in ipairs(sides) do
                if turtle.equipLeft() or turtle.equipRight() then
                    rednet.open(side)
                    lib_ssh.print_debug("Modem equipped and opened")
                    return true
                end
            end
        end
    end
    
    lib_ssh.print_debug("No modem found or equipped")
    return false
end

-- Function to send a message to a specific ID
function lib_ssh.sendMessage(id, message)
    lib_ssh.print_debug("Sending message to " .. id .. ": " .. textutils.serialize(message))
    return rednet.send(id, textutils.serialize(message), "ssh_protocol")
end

-- Function to receive a message
function lib_ssh.receiveMessage(timeout)
    lib_ssh.print_debug("Waiting for message with timeout " .. tostring(timeout))
    local sender, message, protocol = rednet.receive("ssh_protocol", timeout)
    if sender and message then
        lib_ssh.print_debug("Received message from " .. tostring(sender) .. ": " .. message)
        return sender, textutils.unserialize(message)
    end
    lib_ssh.print_debug("No message received within timeout")
    return nil, nil
end

return lib_ssh