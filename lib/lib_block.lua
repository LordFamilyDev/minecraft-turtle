-- lib_block.lua (/lib/lib_block.lua)
-- Turtle Block API Client Library to interact with the Block API Server (/bin/util/blockd)

-- API Commands:
-- blockGet(<direction>) - Get block properties in the specified direction
-- blockGetUp() - Get block properties above the turtle
-- blockGetDown() - Get block properties below the turtle
-- blockSet(properties, <direction>) - Set block properties in the specified direction
-- blockSetUp(properties) - Set block properties above the turtle
-- blockSetDown(properties) - Set block properties below the turtle
-- groundPenetratingRadar(filter_string) - Scan for specified ore types below the turtle and track veins

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

    local result, error = sendRequest("block_get", x, y, z)
    if not result then
        return nil, "Unable to get turtle information: " .. tostring(error)
    end

    if result.error then
        return nil, result.error
    end

    local facing
    if result.block_state and result.block_state.facing then
        if result.block_state.facing == "north" then facing = 0
        elseif result.block_state.facing == "east" then facing = 1
        elseif result.block_state.facing == "south" then facing = 2
        elseif result.block_state.facing == "west" then facing = 3
        else
            return nil, "Unknown facing direction: " .. result.block_state.facing
        end
    else
        return nil, "Unable to determine facing from block state"
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

function blockAPI.getTurtlePositionAndFacing()
    local x, y, z = gps.locate()
    if not x then
        return nil, "Unable to get GPS coordinates"
    end

    local result, error = sendRequest("block_get", x, y, z)
    if not result then
        return nil, "Unable to get turtle information: " .. tostring(error)
    end

    if result.error then
        return nil, result.error
    end

    local facing
    if result.block_state and result.block_state.facing then
        if result.block_state.facing == "north" then facing = 0
        elseif result.block_state.facing == "east" then facing = 1
        elseif result.block_state.facing == "south" then facing = 2
        elseif result.block_state.facing == "west" then facing = 3
        else
            return nil, "Unknown facing direction: " .. result.block_state.facing
        end
    else
        return nil, "Unable to determine facing from block state"
    end

    return {x = x, y = y, z = z, facing = facing}
end

-- Helper function to check if a block matches the filter
local function blockMatchesFilter(block_type, filter_list)
    for ore in pairs(filter_list) do
        if block_type:lower():find(ore) then
            return ore
        end
    end
    return nil
end

function blockAPI.chunkScan(filterList)
    local x, y, z = gps.locate()
    if not x then
        return nil, "Unable to get GPS coordinates"
    end

    -- Determine chunk boundaries
    local chunkStartX = math.floor(x / 16) * 16
    local chunkStartZ = math.floor(z / 16) * 16
    local chunkEndX = chunkStartX + 15
    local chunkEndZ = chunkStartZ + 15

    local scannedPoints = {}
    local oresToCheck = {}
    local oresFound = {}

    local function isInChunk(px, py, pz)
        return px >= chunkStartX and px <= chunkEndX and
               pz >= chunkStartZ and pz <= chunkEndZ and
               py >= -62 and py <= y - 1
    end

    local function addToScan(px, py, pz)
        local key = px .. "," .. py .. "," .. pz
        if not scannedPoints[key] and isInChunk(px, py, pz) then
            scannedPoints[key] = true
            table.insert(oresToCheck, {px, py, pz})
            return true
        end
        return false
    end

    -- Random sampling
    while #oresToCheck < 4000 do
        local py
        if math.random() < 0.75 then
            py = math.floor(normalDistribution(-59, 3.5))
            py = math.max(-59, math.min(-45, py))
        else
            py = math.floor(normalDistribution(14, 3.5))
            py = math.max(8, math.min(22, py))
        end

        local px = math.random(chunkStartX, chunkEndX)
        local pz = math.random(chunkStartZ, chunkEndZ)

        addToScan(px, py, pz)
    end

    -- Scan points
    local function scanPoint(px, py, pz)
        local result, error = sendRequest("block_get", px, py, pz)
        if result and result.block_type then
            for _, ore in ipairs(filterList) do
                if result.block_type:find(ore) then
                    table.insert(oresFound, {px, py, pz, result.block_type})
                    -- Check neighbors
                    addToScan(px+1, py, pz)
                    addToScan(px-1, py, pz)
                    addToScan(px, py+1, pz)
                    addToScan(px, py-1, pz)
                    addToScan(px, py, pz+1)
                    addToScan(px, py, pz-1)
                    break
                end
            end
        elseif error then
            print("Error scanning block at " .. px .. "," .. py .. "," .. pz .. ": " .. error)
        end
    end

    local totalScanned = 0
    local totalToScan = #oresToCheck
    while #oresToCheck > 0 do
        local point = table.remove(oresToCheck, 1)
        scanPoint(unpack(point))
        totalScanned = totalScanned + 1

        if totalScanned % 100 == 0 or #oresToCheck == 0 then
            print(string.format("%d / %d scanned, %d ores found", 
                totalScanned, totalToScan, #oresFound))
        end
    end

    return oresFound
end

-- Helper function to get neighboring blocks
local function getNeighbors(x, y, z)
    return {
        {x-1, y, z}, {x+1, y, z},
        {x, y-1, z}, {x, y+1, z},
        {x, y, z-1}, {x, y, z+1}
    }
end

function blockAPI.groundPenetratingRadar(filter_string)
    local pos, error = getTurtlePositionAndFacing()
    if not pos then
        return nil, error
    end

    local filter_list = {}
    for ore in filter_string:gmatch("%w+") do
        filter_list[ore:lower()] = true
    end

    local ScanData = {}
    local to_scan = {}
    local scanned = {}

    -- Initial vertical scan
    for y = pos.y - 1, -62, -1 do
        local result, error = sendRequest("block_get", pos.x, y, pos.z)
        if result and result.block_type then
            local matched_ore = blockMatchesFilter(result.block_type, filter_list)
            if matched_ore then
                if not ScanData[matched_ore] then
                    ScanData[matched_ore] = {}
                end
                table.insert(ScanData[matched_ore], {pos.x, y, pos.z})
                
                -- Add neighboring blocks to the scan list
                for _, neighbor in ipairs(getNeighbors(pos.x, y, pos.z)) do
                    table.insert(to_scan, neighbor)
                end
            end
        elseif error then
            print("Error scanning block at " .. pos.x .. "," .. y .. "," .. pos.z .. ": " .. error)
        end
        
        -- Add a small delay to avoid overwhelming the server
        os.sleep(0.05)
    end

    -- Scan adjacent blocks for veins
    while #to_scan > 0 do
        local current = table.remove(to_scan)
        local x, y, z = unpack(current)
        
        -- Check if we've already scanned this block
        local key = x .. "," .. y .. "," .. z
        if scanned[key] then
            goto continue
        end
        scanned[key] = true

        local result, error = sendRequest("block_get", x, y, z)
        if result and result.block_type then
            local matched_ore = blockMatchesFilter(result.block_type, filter_list)
            if matched_ore then
                if not ScanData[matched_ore] then
                    ScanData[matched_ore] = {}
                end
                table.insert(ScanData[matched_ore], {x, y, z})
                
                -- Add neighboring blocks to the scan list
                for _, neighbor in ipairs(getNeighbors(x, y, z)) do
                    table.insert(to_scan, neighbor)
                end
            end
        elseif error then
            print("Error scanning block at " .. x .. "," .. y .. "," .. z .. ": " .. error)
        end
        
        -- Add a small delay to avoid overwhelming the server
        os.sleep(0.05)
        
        ::continue::
    end

    return ScanData
end

return blockAPI