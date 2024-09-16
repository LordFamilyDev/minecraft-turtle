-- /bin/util/chunkd

local protocol = "chunk_api"
local discovery_protocol = "chunk_api_discovery"
local host_id = os.getComputerID()
local file_path = "/chunkd_data.json"

-- Open the rednet modem
local modem = peripheral.find("modem")
if not modem then
    error("No modem found")
end
rednet.open(peripheral.getName(modem))

-- ForceLoadedChunkTable
local ForceLoadedChunkTable = {}

-- Helper functions
local function saveTable()
    local file = fs.open(file_path, "w")
    file.write(textutils.serialize(ForceLoadedChunkTable))
    file.close()
end

local function loadTable()
    if fs.exists(file_path) then
        local file = fs.open(file_path, "r")
        ForceLoadedChunkTable = textutils.unserialize(file.readAll())
        file.close()
    end
end

local function getChunkCoords(x, z)
    return math.floor(x / 16) * 16, math.floor(z / 16) * 16
end

local function getCurrentTimestamp()
    return math.floor(os.epoch("utc") / 1000)
end

local function cleanupTable()
    local currentTime = getCurrentTimestamp()
    local changed = false
    for key, value in pairs(ForceLoadedChunkTable) do
        if value ~= 0 and value <= currentTime then
            local x, z = string.match(key, "(%d+),(%d+)")
            commands.exec("forceload remove " .. x .. " " .. z)
            ForceLoadedChunkTable[key] = nil
            changed = true
        end
    end
    if changed then
        saveTable()
    end
end

-- API handlers
local api = {}

function api.set_chunk(sender, x, y, z, time)
    local chunkX, chunkZ = getChunkCoords(x, z)
    local key = chunkX .. "," .. chunkZ
    local currentTime = getCurrentTimestamp()
    local expirationTime = time == 0 and 0 or (currentTime + time)

    if ForceLoadedChunkTable[key] then
        if time == 0 or (ForceLoadedChunkTable[key] ~= 0 and expirationTime > ForceLoadedChunkTable[key]) then
            ForceLoadedChunkTable[key] = expirationTime
        end
    else
        ForceLoadedChunkTable[key] = expirationTime
        commands.exec("forceload add " .. chunkX .. " " .. chunkZ)
    end

    saveTable()
    return textutils.serializeJSON({success = true})
end

function api.get_chunk(sender, x, y, z)
    local chunkX, chunkZ = getChunkCoords(x, z)
    local key = chunkX .. "," .. chunkZ
    local timestamp = ForceLoadedChunkTable[key] or 0
    return textutils.serializeJSON({x = chunkX, z = chunkZ, timestamp = timestamp})
end

function api.del_chunk(sender, x, y, z)
    local chunkX, chunkZ = getChunkCoords(x, z)
    local key = chunkX .. "," .. chunkZ
    
    if ForceLoadedChunkTable[key] then
        ForceLoadedChunkTable[key] = nil
        saveTable()
        commands.exec("forceload remove " .. chunkX .. " " .. chunkZ)
        return textutils.serializeJSON({success = true, message = "Chunk force-loading removed"})
    else
        return textutils.serializeJSON({success = false, message = "Chunk was not force-loaded"})
    end
end

function api.get_all_chunks()
    return textutils.serializeJSON(ForceLoadedChunkTable)
end

-- Main loop
local function handleMessages()
    local lastCleanup = getCurrentTimestamp()

    while true do
        local currentTime = getCurrentTimestamp()
        if currentTime - lastCleanup >= 60 then  -- Check every minute
            cleanupTable()
            lastCleanup = currentTime
        end

        local sender, message, msgProtocol = rednet.receive(1)  -- 1 second timeout
        if sender and message then
            if msgProtocol == discovery_protocol and message == "DISCOVER" then
                rednet.send(sender, "ACKNOWLEDGE", discovery_protocol)
            elseif msgProtocol == protocol and type(message) == "table" then
                local response
                if message.action == "set_chunk" and message.x and message.z and message.time then
                    response = api.set_chunk(sender, message.x, message.y or 0, message.z, message.time)
                elseif message.action == "get_chunk" and message.x and message.z then
                    response = api.get_chunk(sender, message.x, message.y or 0, message.z)
                elseif message.action == "del_chunk" and message.x and message.z then
                    response = api.del_chunk(sender, message.x, message.y or 0, message.z)
                elseif message.action == "get_all_chunks" then
                    response = api.get_all_chunks()
                else
                    response = textutils.serializeJSON({error = "Invalid request"})
                end
                rednet.send(sender, response, protocol)
            end
        end
    end
end

-- Startup
loadTable()
cleanupTable()
print("Chunk API Server started on computer " .. host_id)
print("Use protocol: " .. protocol)
handleMessages()