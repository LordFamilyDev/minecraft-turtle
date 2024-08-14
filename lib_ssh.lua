-- lib_ssh.lua

local lib_ssh = {}

-- Function to find and use the modem
function lib_ssh.setupModem()
    local sides = {"left", "right", "back"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
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
                    return true
                end
            end
        end
    end
    
    return false
end

-- Function to send a message to a specific ID
function lib_ssh.sendMessage(id, message)
    return rednet.send(id, textutils.serialize(message), "ssh_protocol")
end

-- Function to receive a message
function lib_ssh.receiveMessage(timeout)
    local sender, message = rednet.receive("ssh_protocol", timeout)
    if message then
        return sender, textutils.unserialize(message)
    end
    return nil, nil
end

return lib_ssh