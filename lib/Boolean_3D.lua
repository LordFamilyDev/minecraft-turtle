-- 3D Boolean Operations Module
local Boolean3D = {}
Boolean3D.__index = Boolean3D

-- Initialize the grid with a size of x, y, z
function Boolean3D:new(x_size, y_size, z_size)
    local obj = {
        grid = {},
        x_size = x_size,
        y_size = y_size,
        z_size = z_size
    }
    -- Initialize the grid with 0s (empty space)
    for x = 1, x_size do
        obj.grid[x] = {}
        for y = 1, y_size do
            obj.grid[x][y] = {}
            for z = 1, z_size do
                obj.grid[x][y][z] = 0
            end
        end
    end
    setmetatable(obj, Boolean3D)
    return obj
end

--operations are "add", "subtract", "overwrite".  The specified operation is applied to how inside and outside values are applied to the grid
-- Helper function to apply operations
local function applyOperation(currentVal, newVal, operation)
    if operation == "add" then
        return currentVal + newVal
    elseif operation == "subtract" then
        return currentVal - newVal
    elseif operation == "overwrite" then
        return newVal
    end
    return currentVal  -- Default, if no operation matches
end

-- Add a sphere to the grid
function Boolean3D:sphere(center_x, center_y, center_z, radius, insideVal, outsideVal, operation)
    for x = 1, self.x_size do
        for y = 1, self.y_size do
            for z = 1, self.z_size do
                local dist = math.sqrt((x - center_x)^2 + (y - center_y)^2 + (z - center_z)^2)
                if dist <= radius then
                    -- Inside the sphere
                    self.grid[x][y][z] = applyOperation(self.grid[x][y][z], insideVal, operation)
                else
                    -- Outside the sphere
                    self.grid[x][y][z] = applyOperation(self.grid[x][y][z], outsideVal, operation)
                end
            end
        end
    end
end

-- Add a rectangular prism to the grid
function Boolean3D:addRectangularPrism(center_x, center_y, center_z, x_len, y_len, z_len, insideVal, outsideVal, operation)
    -- Calculate the minimum and maximum boundaries for the rectangular prism
    local x_min = math.max(1, math.floor(center_x - (x_len - 1) / 2))
    local x_max = math.min(self.x_size, math.floor(center_x + (x_len - 1) / 2))
    local y_min = math.max(1, math.floor(center_y - (y_len - 1) / 2))
    local y_max = math.min(self.y_size, math.floor(center_y + (y_len - 1) / 2))
    local z_min = math.max(1, math.floor(center_z - (z_len - 1) / 2))
    local z_max = math.min(self.z_size, math.floor(center_z + (z_len - 1) / 2))

    -- Iterate through the grid and apply values inside and outside the prism
    for x = 1, self.x_size do
        for y = 1, self.y_size do
            for z = 1, self.z_size do
                if x >= x_min and x <= x_max and y >= y_min and y <= y_max and z >= z_min and z <= z_max then
                    -- Inside the rectangular prism
                    self.grid[x][y][z] = applyOperation(self.grid[x][y][z], insideVal, operation)
                else
                    -- Outside the rectangular prism
                    self.grid[x][y][z] = applyOperation(self.grid[x][y][z], outsideVal, operation)
                end
            end
        end
    end
end

-- Apply a custom continuous function of x and z, like y = f(x, z)
function Boolean3D:customFunction(func_xz, aboveVal, belowVal, operation)
    for x = 1, self.x_size do
        for z = 1, self.z_size do
            local func_y = func_xz(x, z)  -- Get the y value from the function
            for y = 1, self.y_size do
                if y <= func_y then
                    -- Below or on the function
                    self.grid[x][y][z] = applyOperation(self.grid[x][y][z], belowVal, operation)
                else
                    -- Above the function
                    self.grid[x][y][z] = applyOperation(self.grid[x][y][z], aboveVal, operation)
                end
            end
        end
    end
end

-- Function to create a paraboloid equation based on parameters a, b, c
function Boolean3D.createParaboloid(a, b, c, x0, y0, z0)
    return function(x, z)
        return a + b * ((x+x0)^2) + c * ((z+z0)^2) + y0
    end
end

-- Rotate the grid 90 degrees along the specified axis (x, y, or z)
function Boolean3D:rotate_90(axis)
    local new_grid = {}
    -- Initialize a new grid for the rotated values
    for x = 1, self.x_size do
        new_grid[x] = {}
        for y = 1, self.y_size do
            new_grid[x][y] = {}
            for z = 1, self.z_size do
                new_grid[x][y][z] = 0
            end
        end
    end

    if axis == "x" then
        for x = 1, self.x_size do
            for y = 1, self.y_size do
                for z = 1, self.z_size do
                    new_grid[x][z][self.y_size - y + 1] = self.grid[x][y][z]
                end
            end
        end
    elseif axis == "y" then
        for x = 1, self.x_size do
            for y = 1, self.y_size do
                for z = 1, self.z_size do
                    new_grid[z][y][self.x_size - x + 1] = self.grid[x][y][z]
                end
            end
        end
    elseif axis == "z" then
        for x = 1, self.x_size do
            for y = 1, self.y_size do
                for z = 1, self.z_size do
                    new_grid[self.z_size - z + 1][y][x] = self.grid[x][y][z]
                end
            end
        end
    end
    self.grid = new_grid  -- Update the grid with the rotated version
end

-- Remove all points that have 6 nonzero neighbors, accounting for edges
function Boolean3D:thinShell()
    local new_grid = {}

    -- Initialize a new grid to copy values
    for x = 1, self.x_size do
        new_grid[x] = {}
        for y = 1, self.y_size do
            new_grid[x][y] = {}
            for z = 1, self.z_size do
                new_grid[x][y][z] = self.grid[x][y][z]  -- Default copy
            end
        end
    end

    -- Iterate over the grid and check for fully enclosed points
    for x = 1, self.x_size do
        for y = 1, self.y_size do
            for z = 1, self.z_size do
                if self.grid[x][y][z] > 0 then
                    local neighbor_count = 0
                    local val = self.grid[x][y][z]

                    -- Check the 6 adjacent neighbors, considering edges
                    -- Right neighbor (or edge)
                    if x < self.x_size and self.grid[x+1][y][z] == val then
                        neighbor_count = neighbor_count + 1
                    elseif x == self.x_size then
                        neighbor_count = neighbor_count + 1  -- Edge bonus
                    end

                    -- Left neighbor (or edge)
                    if x > 1 and self.grid[x-1][y][z] == val then
                        neighbor_count = neighbor_count + 1
                    elseif x == 1 then
                        neighbor_count = neighbor_count + 1  -- Edge bonus
                    end

                    -- Up neighbor (or edge)
                    if y < self.y_size and self.grid[x][y+1][z] == val then
                        neighbor_count = neighbor_count + 1
                    elseif y == self.y_size then
                        neighbor_count = neighbor_count + 1  -- Edge bonus
                    end

                    -- Down neighbor (or edge)
                    if y > 1 and self.grid[x][y-1][z] == val then
                        neighbor_count = neighbor_count + 1
                    elseif y == 1 then
                        neighbor_count = neighbor_count + 1  -- Edge bonus
                    end

                    -- Forward (z+) neighbor (or edge)
                    if z < self.z_size and self.grid[x][y][z+1] == val then
                        neighbor_count = neighbor_count + 1
                    elseif z == self.z_size then
                        neighbor_count = neighbor_count + 1  -- Edge bonus
                    end

                    -- Backward (z-) neighbor (or edge)
                    if z > 1 and self.grid[x][y][z-1] == val then
                        neighbor_count = neighbor_count + 1
                    elseif z == 1 then
                        neighbor_count = neighbor_count + 1  -- Edge bonus
                    end

                    -- If the point is fully enclosed (6 neighbors or edge bonus), remove it
                    if neighbor_count == 6 then
                        new_grid[x][y][z] = 0  -- Remove fully enclosed point
                    end
                end
            end
        end
    end

    -- Update the grid with the new thinned shell grid
    self.grid = new_grid
end

-- Overwrite all points in the grid where value equals valFrom to valTo
function Boolean3D:replaceValue(valFrom, valTo)
    for x = 1, self.x_size do
        for y = 1, self.y_size do
            for z = 1, self.z_size do
                -- Check if the current value equals valFrom
                if self.grid[x][y][z] == valFrom then
                    self.grid[x][y][z] = valTo  -- Replace it with valTo
                end
            end
        end
    end
end

-- Get a slice from the grid at a specific y-index
function Boolean3D:getXZSlice(y_index)
    if y_index < 1 or y_index > self.y_size then
        print("Invalid y_index")
        return nil
    end
    local slice = {}
    for x = 1, self.x_size do
        slice[x] = {}
        for z = 1, self.z_size do
            slice[x][z] = self.grid[x][y_index][z]
        end
    end
    return slice
end

-- Returns a list of points {x, y, z, value} for a specific XZ slice at y_index
function Boolean3D:getXZSlice_points(y_index, centeredFlag)
    local points = {}
    
    -- Ensure y_index is within bounds
    if y_index < 1 or y_index > self.y_size then
        print("Invalid y_index")
        return points
    end

    -- Iterate over the X and Z dimensions at the specified Y level
    for x = 1, self.x_size do
        for z = 1, self.z_size do
            local value = self.grid[x][y_index][z]
            if value > 0 then
                if centeredFlag then
                    table.insert(points, {x - math.ceil(self.x_size/2), y_index, z - math.ceil(self.z_size/2), value})
                else
                    table.insert(points, {x, y_index, z, value})
                end
                
            end
        end
    end
    
    return points
end

-- Count and print the occurrences of each unique value in the grid
function Boolean3D:countUniqueValues()
    local valueCounts = {}

    -- Iterate through the entire grid
    for x = 1, self.x_size do
        for y = 1, self.y_size do
            for z = 1, self.z_size do
                local value = self.grid[x][y][z]

                -- Initialize the count for a new value
                if valueCounts[value] == nil then
                    valueCounts[value] = 0
                end

                -- Increment the count for the current value
                valueCounts[value] = valueCounts[value] + 1
            end
        end
    end

    -- Print out the value counts
    print("Unique Value Counts:")
    for value, count in pairs(valueCounts) do
        print("Value: " .. value .. " Count: " .. count)
    end
end

function Boolean3D:debugPrint()
    for y = 1, self.y_size do
        print("Slice at Y =", y)
        for x = 1, self.x_size do
            for z = 1, self.z_size do
                io.write(self.grid[x][y][z] .. " ")  -- Print grid value
            end
            io.write("\n")  -- New line after each row (z-axis)
        end
        io.read()  -- Pause for user input to inspect each slice
        print("\n")  -- Separate slices by a blank line
    end
end

-- Return the module
return Boolean3D
