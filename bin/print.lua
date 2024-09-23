-- print.lua

local blockAPI = require("/lib/lib_block")
local lib_inv = require("/lib/lib_inv")

-- Modem management
local wirelessModem, wiredModem

local function findModems()
    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        local type = peripheral.getType(name)
        if type == "modem" then
            if peripheral.call(name, "isWireless") then
                wirelessModem = peripheral.wrap(name)
                print("Found wireless modem: " .. name)
            else
                wiredModem = peripheral.wrap(name)
                print("Found wired modem: " .. name)
            end
        end
    end
    if not wirelessModem then print("No wireless modem found") end
    if not wiredModem then print("No wired modem found") end
end

local function openWirelessModem()
    if wirelessModem then
        rednet.close()
        rednet.open(peripheral.getName(wirelessModem))
        print("Opened wireless modem")
    else
        error("No wireless modem found")
    end
end

local function openWiredModem()
    if wiredModem then
        rednet.close()
        rednet.open(peripheral.getName(wiredModem))
        print("Opened wired modem")
    else
        error("No wired modem found")
    end
end

-- Wrapper functions for lib_inv operations
local function invGet(itemName, count)
    openWiredModem()
    print("Attempting to get " .. count .. " of " .. itemName)
    local success, result = pcall(lib_inv.get, itemName, count)
    openWirelessModem()
    if not success then
        print("Error in invGet for " .. itemName .. ": " .. tostring(result))
    else
        print("Successfully got " .. itemName)
    end
    return success
end

local function invPut(itemName, count)
    openWiredModem()
    print("Attempting to put " .. count .. " of " .. itemName)
    local success, result = pcall(lib_inv.put, itemName, count)
    openWirelessModem()
    if not success then
        print("Error in invPut for " .. itemName .. ": " .. tostring(result))
    else
        print("Successfully put " .. itemName)
    end
    return success
end

-- Wrapper function for blockAPI operations
local function blockAPIOperation(operation, ...)
    openWirelessModem()
    local result = operation(...)
    return result
end

-- Function to read JSON file
local function readJSON(path)
    local file = fs.open(path, "r")
    if not file then error("Could not open file: " .. path) end
    local content = file.readAll()
    file.close()
    return textutils.unserializeJSON(content)
end

-- Turtle state
local position = {x = -1, y = 0, z = -1}  -- Start at -1, 0, -1
local direction = 0 -- 0: +x, 90: +z, 180: -x, 270: -z
local initialDirection = 0 -- Store the initial direction of the turtle

-- PrintObject constructor
local function PrintObject(x, y, z, blockType, properties)
    return {x = x, y = y, z = z, blockType = blockType, properties = properties}
end

-- Movement functions
local function moveForward()
    if turtle.forward() then
        if direction == 0 then position.x = position.x + 1
        elseif direction == 90 then position.z = position.z + 1
        elseif direction == 180 then position.x = position.x - 1
        elseif direction == 270 then position.z = position.z - 1
        end
        return true
    end
    return false
end

local function moveUp()
    if turtle.up() then
        position.y = position.y + 1
        return true
    end
    return false
end

local function moveDown()
    if turtle.down() then
        position.y = position.y - 1
        return true
    end
    return false
end

local function turnLeft()
    turtle.turnLeft()
    direction = (direction - 90) % 360
end

local function turnRight()
    turtle.turnRight()
    direction = (direction + 90) % 360
end

-- Optimized function to turn to a target direction
local function turnToDirection(targetDirection)
    local diff = (targetDirection - direction + 360) % 360
    if diff == 270 then
        turnLeft()
    else
        while direction ~= targetDirection do
            turnRight()
        end
    end
end

-- Function to calculate Manhattan distance
local function manhattanDistance(x1, z1, x2, z2)
    return math.abs(x1 - x2) + math.abs(z1 - z2)
end

-- Function to find the nearest print object
local function findNearestPrintObject(printObjects)
    local nearest = nil
    local minDistance = math.huge
    for i, obj in ipairs(printObjects) do
        local distance = manhattanDistance(position.x, position.z, obj.x, obj.z)
        if distance < minDistance then
            minDistance = distance
            nearest = i
        end
    end
    return nearest
end

-- Function to move turtle to print object
local function moveToPrintObject(obj)
    -- Move vertically
    while position.y < obj.y do moveUp() end
    while position.y > obj.y do moveDown() end

    -- Move horizontally
    if position.x ~= obj.x then
        turnToDirection(obj.x > position.x and 0 or 180)
        while position.x ~= obj.x do moveForward() end
    end
    if position.z ~= obj.z then
        turnToDirection(obj.z > position.z and 90 or 270)
        while position.z ~= obj.z do moveForward() end
    end
end

-- Function to return turtle to refill position
local function goToRefillPosition()
    print("Returning to refill position")
    -- Move to x = -1, z = -1 first
    turnToDirection(180) -- Face -x direction
    while position.x > -1 do moveForward() end
    turnToDirection(270) -- Face -z direction
    while position.z > -1 do moveForward() end
    
    -- Then move down to y = 0
    while position.y > 0 do moveDown() end
    
    -- Finally, face the original direction (+x)
    turnToDirection(0)
    print("At refill position")
end

-- Function to adjust facing direction relative to initial turtle direction
local function adjustFacingDirection(facing)
    local facingMap = {north = 0, east = 90, south = 180, west = 270}
    local reverseFacingMap = {[180] = "north", [270] = "east", [0] = "south", [90] = "west"}
    
    -- Convert facing to absolute angle
    local absoluteFacing = facingMap[facing]
    if not absoluteFacing then
        return facing  -- Return original facing if it's not a cardinal direction
    end
    
    -- Calculate the relative angle considering the initial direction
    local relativeAngle = (absoluteFacing - initialDirection + 360) % 360
    
    -- Invert the relative angle
    local invertedAngle = (360 - relativeAngle) % 360
    
    -- Convert back to cardinal direction
    return reverseFacingMap[invertedAngle] or facing
end

-- Function to map block types to slot indices
local blockTypeToSlot = {}
local function mapBlockTypesToSlots()
    blockTypeToSlot = {}  -- Reset the mapping
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if not blockTypeToSlot[item.name] then
                blockTypeToSlot[item.name] = slot - 1  -- Convert to 0-based index
            end
            print("Mapped " .. item.name .. " to slot " .. (slot - 1))
        end
    end
end

-- Function to count blocks in a layer
local function countBlocksInLayer(structure, layer)
    local blockCounts = {}
    local totalBlocks = 0
    
    local layerData = structure.layerMap[layer + 1]
    if layerData then
        for x = 0, #layerData - 1 do
            local column = layerData[x + 1]
            for z = 0, #column - 1 do
                local block = column:sub(z + 1, z + 1)
                local blockInfo = structure.palette[block]
                if blockInfo and blockInfo.name ~= "minecraft:air" then
                    blockCounts[blockInfo.name] = (blockCounts[blockInfo.name] or 0) + 1
                    totalBlocks = totalBlocks + 1
                end
            end
        end
    end
    
    return blockCounts, totalBlocks
end

-- Function to fill inventory based on block percentages
local function fillInventoryByPercentage(structure, layer, emptySlots)
    local blockCounts, totalBlocks = countBlocksInLayer(structure, layer)
    local sortedBlocks = {}
    for blockName, count in pairs(blockCounts) do
        table.insert(sortedBlocks, {name = blockName, count = count})
    end
    table.sort(sortedBlocks, function(a, b) return a.count > b.count end)
    
    local slotsToFill = emptySlots
    for _, block in ipairs(sortedBlocks) do
        if slotsToFill <= 0 then break end
        local percentage = block.count / totalBlocks
        local slotsForThisBlock = math.floor(percentage * emptySlots + 0.5)
        if slotsForThisBlock > 0 then
            local success = invGet(block.name, slotsForThisBlock * 64)
            if success then
                slotsToFill = slotsToFill - slotsForThisBlock
            end
        end
    end
end

-- Initialize inventory at the start
local function initializeInventory(structure)
    print("Initializing inventory")
    -- Transfer any items in turtle's inventory to remote chests
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            invPut(item.name, item.count)
        end
    end

    -- Get unique block types from palette
    local uniqueBlocks = {}
    for _, blockInfo in pairs(structure.palette) do
        if blockInfo.name ~= "minecraft:air" then
            uniqueBlocks[blockInfo.name] = true
        end
    end

    -- Get at least one stack of each unique block
    local filledSlots = 0
    for blockName in pairs(uniqueBlocks) do
        print("Attempting to get " .. blockName)
        if invGet(blockName, 64) then
            filledSlots = filledSlots + 1
        else
            print("Failed to get " .. blockName .. ". Continuing with next block type.")
        end
        if filledSlots >= 16 then break end
    end

    -- Fill remaining slots based on percentages in the first layer
    if filledSlots < 16 then
        fillInventoryByPercentage(structure, 0, 16 - filledSlots)
    end

    -- Map block types to slots
    mapBlockTypesToSlots()
    print("Inventory initialization complete")
end

-- Function to refill inventory
local function refillInventory(structure, currentLayer)
    print("Refilling inventory for layer " .. currentLayer)
    -- Clear current inventory
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            invPut(item.name, item.count)
        end
    end

    -- Get unique block types from palette
    local uniqueBlocks = {}
    for _, blockInfo in pairs(structure.palette) do
        if blockInfo.name ~= "minecraft:air" then
            uniqueBlocks[blockInfo.name] = true
        end
    end

    -- Get at least one stack of each unique block
    local filledSlots = 0
    for blockName in pairs(uniqueBlocks) do
        print("Attempting to get " .. blockName)
        if invGet(blockName, 64) then
            filledSlots = filledSlots + 1
        else
            print("Failed to get " .. blockName .. ". Continuing with next block type.")
        end
        if filledSlots >= 16 then break end
    end

    -- Fill remaining slots based on percentages in the current layer
    if filledSlots < 16 then
        fillInventoryByPercentage(structure, currentLayer, 16 - filledSlots)
    end

    -- Remap block types to slots
    mapBlockTypesToSlots()
    print("Inventory refill complete")
end

-- Function to find a block type in inventory
local function findBlockTypeInInventory(blockType)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == blockType then
            return slot - 1  -- Convert to 0-based index
        end
    end
    return nil
end

-- Function to select the correct slot for a block type
local function selectSlotForBlockType(blockType, structure)
    local slotIndex = blockTypeToSlot[blockType]
    if slotIndex then
        if turtle.getItemCount(slotIndex + 1) > 0 then
            return turtle.select(slotIndex + 1)
        else
            -- Try to find the block type in other slots
            local newSlotIndex = findBlockTypeInInventory(blockType)
            if newSlotIndex then
                blockTypeToSlot[blockType] = newSlotIndex  -- Update the mapping
                print("Updated " .. blockType .. " mapping to slot " .. newSlotIndex)
                return turtle.select(newSlotIndex + 1)
            else
                -- If we're out of this block type, refill inventory
                print("Ran out of " .. blockType .. ". Refilling inventory...")
                local currentY = position.y
                goToRefillPosition()
                refillInventory(structure, currentY)
                moveToPrintObject({x = position.x, y = currentY, z = position.z})
                return selectSlotForBlockType(blockType, structure)  -- Try again after refilling
            end
        end
    else
        -- If the block type is not mapped, try to find it in inventory
        local newSlotIndex = findBlockTypeInInventory(blockType)
        if newSlotIndex then
            blockTypeToSlot[blockType] = newSlotIndex  -- Update the mapping
            print("Mapped " .. blockType .. " to slot " .. newSlotIndex)
            return turtle.select(newSlotIndex + 1)
        else
            print("No slot found for block type: " .. blockType .. ". Refilling inventory...")
            local currentY = position.y
            goToRefillPosition()
            refillInventory(structure, currentY)
            moveToPrintObject({x = position.x, y = currentY, z = position.z})
            return selectSlotForBlockType(blockType, structure)  -- Try again after refilling
        end
    end
end

-- Function to generate print objects for a layer
local function generatePrintObjects(structure, y)
    local printObjects = {}
    local layer = structure.layerMap[y+1]
    if not layer then return printObjects end

    for x = 0, #layer - 1 do
        local column = layer[x+1]
        for z = 0, #column - 1 do
            local block = column:sub(z+1, z+1)
            if block ~= " " then
                local blockInfo = structure.palette[block]
                if blockInfo and blockInfo.name ~= "minecraft:air" then
                    table.insert(printObjects, PrintObject(x, y, z, blockInfo.name, blockInfo.properties))
                end
            end
        end
    end
    return printObjects
end

-- Function to print a single object
local function printObject(obj, structure)
    if obj.blockType == "minecraft:air" then
        -- Skip air blocks
        return true
    end

    if selectSlotForBlockType(obj.blockType, structure) then
        moveToPrintObject(obj)
        if turtle.placeDown() then
            if obj.properties then
                local adjustedProperties = {}
                for k, v in pairs(obj.properties) do
                    if k == "facing" then
                        adjustedProperties[k] = adjustFacingDirection(v)
                    else
                        adjustedProperties[k] = v
                    end
                end

                local success, error = blockAPIOperation(blockAPI.blockSetDown, adjustedProperties)
                if not success then
                    print("Failed to set block properties: " .. tostring(error))
                end
            end
            return true
        else
            print("Failed to place block")
        end
    end
    return false
end

-- Main printing function
local function printStructure(structure)
    local height = #structure.layerMap

    print("Structure height: " .. height)

    -- Get initial turtle position and facing
    local turtleInfo, error = blockAPIOperation(blockAPI.getTurtlePositionAndFacing)
    if not turtleInfo then
        print("Error getting turtle position and facing: " .. tostring(error))
        return
    end
    initialDirection = turtleInfo.facing * 90  -- Convert to degrees
    print("Initial direction: " .. initialDirection)

    -- Initialize inventory
    initializeInventory(structure)

    for y = 0, height - 1 do
        print("Printing layer " .. (y + 1))
        local printObjects = generatePrintObjects(structure, y)
        
        while #printObjects > 0 do
            local nearestIndex = findNearestPrintObject(printObjects)
            local obj = printObjects[nearestIndex]
            
            while not printObject(obj, structure) do
                print("Failed to print object. Retrying...")
                -- The selectSlotForBlockType function will handle refilling if necessary
            end
            
            table.remove(printObjects, nearestIndex)
        end
    end
    print("Structure printing completed!")
    goToRefillPosition()
    print("Returned to starting position.")
end

-- Main execution
local args = {...}
if #args < 1 then
    print("Usage: print <json_file>")
    return
end

findModems()  -- Initialize modem connections
openWirelessModem()  -- Start with wireless modem for block API operations

local jsonFile = args[1]
local structure = readJSON(jsonFile)

-- Print structure information
print("Structure loaded:")
print("Layers: " .. #structure.layerMap)
print("Palette entries: " .. #structure.palette)

-- Print palette information
print("Palette:")
for key, value in pairs(structure.palette) do
    print(key .. ": " .. value.name)
end

-- Confirm start
print("Press any key to start printing...")
os.pullEvent("key")

-- Start printing
printStructure(structure)

-- Cleanup
print("Printing complete. Cleaning up...")
openWirelessModem()  -- Ensure we're on wireless for any final operations

-- Optional: Return any unused blocks to storage
print("Returning unused blocks to storage...")
for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item then
        invPut(item.name, item.count)
    end
end

print("All operations complete. Turtle is ready for next task.")