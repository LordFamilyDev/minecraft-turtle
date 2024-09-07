-- print.lua (Optimized version with cursor and improvements)

-- Function to read JSON file
local function readJSON(path)
    local file = fs.open(path, "r")
    if not file then error("Could not open file: " .. path) end
    local content = file.readAll()
    file.close()
    return textutils.unserializeJSON(content)
end

-- Turtle state
local position = {x = 0, y = 0, z = 0}
local direction = 0 -- 0: +x, 90: +z, 180: -x, 270: -z

-- Cursor state
local cursor = {x = 0, y = 0, z = 0}

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

-- New function to move turtle to cursor position
local function moveToCursor()
    -- Calculate the difference between turtle position and cursor
    local dx = cursor.x - position.x
    local dy = cursor.y - position.y
    local dz = cursor.z - position.z

    -- Move vertically
    while dy > 0 do moveUp() dy = dy - 1 end
    while dy < 0 do moveDown() dy = dy + 1 end

    -- Determine target direction and move horizontally
    if dx ~= 0 then
        turnToDirection(dx > 0 and 0 or 180)
        while dx ~= 0 do
            moveForward()
            dx = dx > 0 and dx - 1 or dx + 1
        end
    end
    if dz ~= 0 then
        turnToDirection(dz > 0 and 90 or 270)
        while dz ~= 0 do
            moveForward()
            dz = dz > 0 and dz - 1 or dz + 1
        end
    end
end

-- New function to return turtle to starting position
local function returnToStart()
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
    if not sourceSlot then return false end

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
            end
        end
        return true
    end
    return false
end

-- Printing function
local function printBlock(structure, x, y, z)
    local layer = structure.layerMap[y+1]
    if not layer then return false end
    local column = layer[x+1]
    if not column then return false end
    local block = column:sub(z+1, z+1)
    if block == " " then return true end -- Air, no need to print
    if selectSlot(block) then
        moveToCursor()
        return turtle.placeDown()
    end
    return false
end

-- Main printing function
local function printStructure(structure)
    local width = #structure.layerMap[1]
    local depth = #structure.layerMap[1][1]
    local height = #structure.layerMap

    print("Structure dimensions: " .. width .. "x" .. depth .. "x" .. height)

    for y = 0, height - 1 do
        print("Printing layer " .. (y + 1))
        cursor.y = y
        for x = 0, width - 1 do
            cursor.x = x
            for z = 0, depth - 1 do
                cursor.z = z
                printBlock(structure, x, y, z)
            end
        end
    end
    print("Structure printing completed!")
    returnToStart()
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