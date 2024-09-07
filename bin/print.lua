-- print.lua

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

local function turnLeft()
    turtle.turnLeft()
    direction = (direction - 90) % 360
end

local function turnRight()
    turtle.turnRight()
    direction = (direction + 90) % 360
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
        local forward = true
        for z = 0, depth - 1 do
            if forward then
                for x = 0, width - 1 do
                    printBlock(structure, position.x, position.y, position.z)
                    if x < width - 1 then moveForward() end
                end
            else
                for x = width - 1, 0, -1 do
                    printBlock(structure, position.x, position.y, position.z)
                    if x > 0 then moveForward() end
                end
            end

            if z < depth - 1 then
                if forward then
                    turnRight()
                    moveForward()
                    turnRight()
                else
                    turnLeft()
                    moveForward()
                    turnLeft()
                end
                forward = not forward
            end
        end

        if y < height - 1 then
            moveUp()
            -- Ensure we're facing the correct direction to start the next layer
            if (depth % 2 == 0) ~= forward then
                turnRight()
                turnRight()
            end
        end
    end
    print("Structure printing completed!")
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