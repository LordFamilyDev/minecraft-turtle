-- /lib/lib_chunk

local lib_chunk = {}

local protocol = "chunk_api"
local discovery_protocol = "chunk_api_discovery"
local server_id = nil

-- Open the rednet modem
local modem = peripheral.find("modem")
if not modem then
    error("No modem found")
end
rednet.open(peripheral.getName(modem))

-- Function to discover the server
local function discoverServer()
    print("Discovering Chunk API Server...")
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
local function sendRequest(action, x, y, z, time)
    if not server_id then
        server_id = discoverServer()
        if not server_id then
            return nil, "Server not found"
        end
    end

    local message = {action = action, x = x, y = y, z = z, time = time}
    rednet.send(server_id, message, protocol)
    local sender, response = rednet.receive(protocol, 5)
    if sender == server_id then
        return textutils.unserializeJSON(response)
    else
        server_id = nil  -- Reset server_id if we didn't get a response
        return nil, "No response from server"
    end
end

-- Function to set a chunk to be force-loaded
function lib_chunk.setChunk(x, z, time)
    return sendRequest("set_chunk", x, 0, z, time)
end

-- Function to get information about a chunk
function lib_chunk.getChunk(x, z)
    return sendRequest("get_chunk", x, 0, z)
end

-- Function to get all force-loaded chunks
function lib_chunk.getAllChunks()
    return sendRequest("get_all_chunks")
end

-- Function to force-discover the server (useful if the server restarts)
function lib_chunk.rediscoverServer()
    server_id = nil
    return discoverServer()
end

function lib_chunk.delChunk(x, z)
    return sendRequest("del_chunk", x, 0, z)
end

return lib_chunk