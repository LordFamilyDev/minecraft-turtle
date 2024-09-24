local move = require("/lib/move")

-- Check for wireless modem
local function checkWirelessModem()
    local sides = {"left", "right"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" and peripheral.call(side, "isWireless") then
            return true
        end
    end
    print("Error: No modem found.")
    return false
end

-- Get GPS coordinates
local function getGPSCoords()
    local x, y, z = gps.locate()
    if not x then
        print("Error: Unable to get GPS coordinates.")
        return nil
    end
    return {x = x, z = z, d = y}
end

-- Determine facing direction
local function determineFacing()
    local initialX, initialD, initialZ = gps.locate()
    
    -- Try moving forward
    if turtle.forward() then
        local newX, newD, newZ  = gps.locate()
        turtle.back()
        return {xd = newX - initialX, zd = newZ - initialZ}
    end
    
    -- If forward fails, try moving backward
    if turtle.back() then
        local newX, newD, newZ = gps.locate()
        turtle.forward()
        return {xd = initialX - newX, zd = initialZ - newZ}
    end
    
    print("Error: Unable to determine facing direction.")
    return nil
end

-- Load home coordinates from file
local function loadHomeCoords()
    if not fs.exists("home.home") then
        print("Error: home.home file not found.")
        return nil
    end
    
    local file = fs.open("home.home", "r")
    local content = file.readAll()
    file.close()
    
    local x, z, d, xd, zd = content:match("(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
    return {x = tonumber(x), z = tonumber(z), d = tonumber(d)},{xd = tonumber(xd), zd = tonumber(zd)}
end

-- Save home coordinates to file
local function saveHomeCoords(coords,direction)
    local file = fs.open("home.home", "w")
    file.write(string.format("%d %d %d %d %d", coords.x, coords.z, coords.d, direction.xd, direction.zd))
    file.close()
    print("Home coordinates saved.")
end

--clear home coordinates file
local function clearHomeCoords()
    fs.delete("home.home")
    print("Home coordinates removed.")
end

-- Main function
local function main(args)
    if not checkWirelessModem() then
        return
    end

    if #args == 0 then
        -- Go home
        local homeCoords, homeDir = loadHomeCoords()
        if not homeCoords then
            return
        end

        local currentCoords = getGPSCoords()
        if not currentCoords then
            return
        end

        local facing = determineFacing()
        if not facing then
            return
        end

        move.setPos(currentCoords.x, currentCoords.z, currentCoords.d, facing.xd, facing.zd)
        move.pathTo(homeCoords.x, homeCoords.z, homeCoords.d)
        move.turnTo(homeDir.xd, homeDir.zd)
        move.setHome()
        print("Arrived at home coordinates.")
    elseif args[1] == "set" then
        -- Set home
        local currentCoords = getGPSCoords()
        print("Coords:",currentCoords.x,currentCoords.z,currentCoords.d)
        if not currentCoords then
            return
        end

        local facing = determineFacing()
        print("Facing:",facing.xd,facing.zd)
        if not facing then
            return
        end

        saveHomeCoords(currentCoords,facing)
    elseif args[1] == "clear" then
        clearHomeCoords()
    else
        print("Usage: goHome [set]")
    end
end

main({...})
