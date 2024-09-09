-- print.lua (Highly optimized version with efficient path planning)

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

-- PrintObject constructor
local function PrintObject(x, y, z, blockType)
    return {x = x, y = y, z = z, blockType = blockType}
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
    -- Move to x = -1, z = -1 first
    turnToDirection(180) -- Face -x direction
    while position.x > -1 do moveForward() end
    turnToDirection(270) -- Face -z direction
    while position.z > -1 do moveForward() end
    
    -- Then move down to y = 0
    while position.y > 0 do moveDown() end
    
    -- Finally, face the original direction (+x)
    turnToDirection(0)
end

-- Function to refill from chest
local function refillFromChest()
    goToRefillPosition()
    print("Refilling from chest...")
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            turtle.select(slot)
            turtle.suckDown()
        end
    end
    print("Refill complete.")
end

-- Inventory management functions
local function findSameItem(sourceSlot)
    local detail = turtle.getItemDetail(sourceSlot)
    if not detail then return nil end

    for i = 1, 16 do
        if i ~= sourceSlot then
            local slotDetail = turtle.getItemDetail(i)
            if slotDetail and slotDetail.name == detail.name then
                return i
            end
        end
    end
    return nil
end

local function replenishSlot(slot)
    local currentCount = turtle.getItemCount(slot)
    if currentCount > 1 then return true end

    local sourceSlot = findSameItem(slot)
    if not sourceSlot then
        refillFromChest()
        sourceSlot = findSameItem(slot)
        if not sourceSlot then return false end
    end

    turtle.select(sourceSlot)
    turtle.transferTo(slot, 64 - currentCount)
    turtle.select(slot)
    return true
end

local function selectSlot(index)
    local slot = tonumber(index, 16) + 1 -- Convert hex to decimal and add 1
    if slot and slot >= 1 and slot <= 16 then
        turtle.select(slot)
        if turtle.getItemCount() <= 1 then
            if not replenishSlot(slot) then
                print("Warning: Running low on items in slot " .. slot)
                return false
            end
        end
        return true
    end
    return false
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
                table.insert(printObjects, PrintObject(x, y, z, block))
            end
        end
    end
    return printObjects
end

-- Function to print a single object
local function printObject(obj)
    if selectSlot(obj.blockType) then
        moveToPrintObject(obj)
        return turtle.placeDown()
    end
    return false
end

-- Main printing function
local function printStructure(structure)
    local height = #structure.layerMap

    print("Structure height: " .. height)

    for y = 0, height - 1 do
        print("Printing layer " .. (y + 1))
        local printObjects = generatePrintObjects(structure, y)
        
        while #printObjects > 0 do
            local nearestIndex = findNearestPrintObject(printObjects)
            local obj = printObjects[nearestIndex]
            
            while not printObject(obj) do
                print("Refilling and retrying...")
                refillFromChest()
                moveToPrintObject(obj)
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

local jsonFile = args[1]
local structure = readJSON(jsonFile)
printStructure(structure)