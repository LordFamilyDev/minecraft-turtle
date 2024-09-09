-- lib_block.lua (/lib/lib_block.lua)
-- Turtle Block API Client Library to interact with the Block API Server (/bin/util/blockd)

-- API Commands:
-- blockGet(<direction>) - Get block properties in the specified direction
-- blockGetUp() - Get block properties above the turtle
-- blockGetDown() - Get block properties below the turtle
-- blockSet(properties, <direction>) - Set block properties in the specified direction
-- blockSetUp(properties) - Set block properties above the turtle
-- blockSetDown(properties) - Set block properties below the turtle

-- Properties: Lua table with the following keys
-- facing - "north", "east", "south", "west"
-- half - "top", "bottom"
-- open - true, false

local protocol = "block_api"
local discovery_protocol = "block_api_discovery"
local server_id = nil

-- Open the rednet modem
local modem = peripheral.find("modem")
if not modem then
    error("No modem found")
end
rednet.open(peripheral.getName(modem))

-- Function to discover the server
local function discoverServer()
    print("Discovering Block API Server...")
    rednet.broadcast("DISCOVER", discovery_protocol)
    local sender, message = rednet.receive(discovery_protocol, 5)
    if sender and message == "ACKNOWLEDGE" then
        print("Server found with ID: " .. sender)
        return sender
    else
        print("Server not found")
        return nil
    end
end

-- Function to send API requests
local function sendRequest(action, ...)
    if not server_id then
        server_id = discoverServer()
        if not server_id then
            return nil, "Server not found"
        end
    end

    local message = {
        action = action,
        params = {...}
    }
    rednet.send(server_id, message, protocol)
    local sender, response = rednet.receive(protocol, 5)
    if sender == server_id then
        return textutils.unserializeJSON(response)
    else
        server_id = nil  -- Reset server_id if we didn't get a response
        return nil, "No response from server"
    end
end

-- Function to get turtle's position and facing
local function getTurtlePositionAndFacing()
    local x, y, z = gps.locate()
    if not x then
        return nil, "Unable to get GPS coordinates"
    end

    local result, error = sendRequest("get_surrounding_blocks", x, y, z)
    if not result then
        return nil, "Unable to get surrounding blocks: " .. tostring(error)
    end

    local blocks = result.blocks
    local facing

    -- Determine facing based on the blocks around the turtle
    if turtle.detect() then
        if blocks[1] then facing = 2      -- Facing south
        elseif blocks[2] then facing = 3  -- Facing west
        elseif blocks[3] then facing = 0  -- Facing north
        elseif blocks[4] then facing = 1  -- Facing east
        end
    else
        if not blocks[1] then facing = 0      -- Facing north
        elseif not blocks[2] then facing = 1  -- Facing east
        elseif not blocks[3] then facing = 2  -- Facing south
        elseif not blocks[4] then facing = 3  -- Facing west
        end
    end

    if not facing then
        return nil, "Unable to determine facing"
    end

    return {x = x, y = y, z = z, facing = facing}
end

-- Function to adjust coordinates based on direction
local function adjustCoordinates(pos, direction)
    local x, y, z = pos.x, pos.y, pos.z
    if direction == "forward" then
        if pos.facing == 0 then z = z - 1
        elseif pos.facing == 1 then x = x + 1
        elseif pos.facing == 2 then z = z + 1
        elseif pos.facing == 3 then x = x - 1
        end
    elseif direction == "up" then
        y = y + 1
    elseif direction == "down" then
        y = y - 1
    end
    return x, y, z
end

-- Block API functions
local blockAPI = {}

function blockAPI.blockGet(direction)
    local pos, error = getTurtlePositionAndFacing()
    if not pos then
        return nil, error
    end

    local x, y, z = adjustCoordinates(pos, direction or "forward")
    return sendRequest("block_get", x, y, z)
end

function blockAPI.blockGetUp()
    return blockAPI.blockGet("up")
end

function blockAPI.blockGetDown()
    return blockAPI.blockGet("down")
end

function blockAPI.blockSet(properties, direction)
    local pos, error = getTurtlePositionAndFacing()
    if not pos then
        return nil, error
    end

    local x, y, z = adjustCoordinates(pos, direction or "forward")
    return sendRequest("block_set", x, y, z, properties)
end

function blockAPI.blockSetUp(properties)
    return blockAPI.blockSet(properties, "up")
end

function blockAPI.blockSetDown(properties)
    return blockAPI.blockSet(properties, "down")
end

return blockAPI