-- blockd (/bin/util/blockd)
-- a server that listens for requests to get or set block properties

-- API Commands:
-- block_get(x, y, z) - Get block properties at the specified coordinates
-- Returns: {block_type, block_state}
-- block_type example: "minecraft:stone"
-- block_state example: {facing = "north", half = "top", open = "false"}

-- block_set(x, y, z, properties) - Set block properties at the specified coordinates
-- returns: {success, result}
-- success: true or false
-- result: string with the result of the setblock command

-- get_surrounding_blocks(x, y, z) - Get block properties for surrounding blocks (N, E, S, W)
-- Returns: a list of blocks (see block_get)

local protocol = "block_api"
local discovery_protocol = "block_api_discovery"
local host_id = os.getComputerID()

-- Open the rednet modem
local modem = peripheral.find("modem")
if not modem then
    error("No modem found")
end
rednet.open(peripheral.getName(modem))

-- Debug logging function
local function log(...)
    local msg = string.format(...)
    print("[LOG] " .. msg)
end

-- Custom deep copy function
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Function to get block information
local function getBlockInfo(x, y, z)
    log("Attempting to get block info at %d, %d, %d", x, y, z)
    local result = commands.getBlockInfo(x, y, z)
    log("getBlockInfo raw result: %s", textutils.serialize(result))
    
    if type(result) == "table" and result.name then
        log("Successfully retrieved block info: %s", textutils.serialize(result))
        return result
    else
        log("Failed to get valid block info")
        return nil, "Invalid or no block at specified coordinates"
    end
end

-- Function to set block properties
local function setBlockProperties(x, y, z, properties)
    local blockInfo, error = getBlockInfo(x, y, z)
    if not blockInfo then
        return false, "Unable to get block information: " .. tostring(error)
    end

    local newState = deepCopy(blockInfo.state or {})
    for k, v in pairs(properties) do
        newState[k] = v
    end

    local stateString = ""
    for k, v in pairs(newState) do
        if type(v) == "boolean" then
            v = v and "true" or "false"
        end
        stateString = stateString .. k .. "=" .. tostring(v) .. ","
    end
    stateString = stateString:sub(1, -2)  -- Remove trailing comma

    local command = string.format(
        "setblock %d %d %d %s[%s]",
        math.floor(x), math.floor(y), math.floor(z),
        blockInfo.name, stateString
    )
    
    log("Executing command: %s", command)
    local success, result = commands.exec(command)
    log("setblock result: success=%s, result=%s", tostring(success), textutils.serialize(result))
    return success, result
end

-- API handlers
local api = {}

function api.block_get(sender, x, y, z)
    log("Received block_get request from %d for %d, %d, %d", sender, x, y, z)
    local blockInfo, error = getBlockInfo(x, y, z)
    if blockInfo then
        local response = textutils.serializeJSON({
            block_type = blockInfo.name,
            block_state = blockInfo.state or {}
        })
        log("Sending response: %s", response)
        return response
    else
        local errorResponse = textutils.serializeJSON({
            error = "Unable to get block information: " .. tostring(error)
        })
        log("Sending error response: %s", errorResponse)
        return errorResponse
    end
end

function api.block_set(sender, x, y, z, properties)
    log("Received block_set request from %d for %d, %d, %d, properties=%s", sender, x, y, z, textutils.serialize(properties))
    local success, result = setBlockProperties(x, y, z, properties)
    local response = textutils.serializeJSON({
        success = success,
        result = result
    })
    log("Sending response: %s", response)
    return response
end

function api.get_surrounding_blocks(sender, x, y, z)
    log("Received get_surrounding_blocks request from %d for %d, %d, %d", sender, x, y, z)
    local blocks = {}
    local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}  -- N, E, S, W
    for i, dir in ipairs(directions) do
        local bx, bz = x + dir[1], z + dir[2]
        local blockInfo, error = getBlockInfo(bx, y, bz)
        if blockInfo then
            blocks[i] = {
                name = blockInfo.name,
                state = blockInfo.state or {}
            }
        else
            blocks[i] = nil
        end
    end
    local response = textutils.serializeJSON({blocks = blocks})
    log("Sending response: %s", response)
    return response
end

-- Main loop to handle incoming messages
local function handleMessages()
    while true do
        local sender, message, msgProtocol = rednet.receive()
        if sender and message then
            if msgProtocol == discovery_protocol and message == "DISCOVER" then
                log("Received discovery request from %d", sender)
                rednet.send(sender, "ACKNOWLEDGE", discovery_protocol)
            elseif msgProtocol == protocol and type(message) == "table" and message.action and api[message.action] then
                log("Received API request from %d: %s", sender, textutils.serialize(message))
                local response = api[message.action](sender, table.unpack(message.params or {}))
                rednet.send(sender, response, protocol)
            else
                log("Received invalid request from %d: %s", sender, textutils.serialize(message))
                rednet.send(sender, textutils.serializeJSON({error = "Invalid request"}), protocol)
            end
        end
    end
end

-- Start the server
log("Block API Server started on computer %d", host_id)
log("Use protocol: %s", protocol)
handleMessages()