local lib = {}

local monitor = peripheral.wrap("monitor_4")  -- Replace "right" with the side your monitor is on

-- Function to draw a single pixel
function drawPixel(x, y, color)
    local originalColor = monitor.getBackgroundColor()
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(color)
    monitor.write(" ")  -- Draw a space with the background color as the "pixel"
    -- Restore the original background color
    monitor.setBackgroundColor(originalColor)
end

-- Function to draw a grid of pixels based on a 2D table of colors
function drawPixels(startX, startY, pixelGrid)
    local originalColor = monitor.getBackgroundColor()
    monitor.setCursorPos(startX, startY)
    local endY = startY
    for rowIndex, row in ipairs(pixelGrid) do
        for colIndex, color in ipairs(row) do
            local x = startX + colIndex - 1
            local y = startY + rowIndex - 1
            drawPixel(x, y, color)
        end
        endY = endY + 1
    end
    -- Restore the original background color
    monitor.setBackgroundColor(originalColor)
    return endY
end

-- Define two-letter color variables
local wh = colors.white
local br = colors.brown
local bl = colors.black
local rd = colors.red
local gr = colors.green
local ye = colors.yellow  -- For the candle flame

-- Cake pixel grid with candles
local cakePixelGrid = {
    -- First row (yellow flames for the candles)
    { bl, bl, ye, bl, bl, ye, bl, bl, ye, bl },
    -- Second row (white candles)
    { bl, bl, wh, bl, bl, wh, bl, bl, wh, bl },
    { bl, bl, wh, bl, bl, wh, bl, bl, wh, bl },
    -- Third row (white icing on top of cake)
    { wh, wh, wh, wh, wh, wh, wh, wh, wh, wh },
    -- Fourth row (cake layer with sprinkles)
    { br, rd, wh, br, gr, br, wh, rd, br, br },
    -- Fifth row (first cake layer)
    { br, br, br, br, br, br, br, br, br, br },
    -- Sixth row (second icing layer)
    { wh, wh, wh, wh, wh, wh, wh, wh, wh, wh },
    -- Seventh row (second cake layer)
    { br, br, br, br, br, br, br, br, br, br },
    -- Eighth row (cake base)
    { br, br, br, br, br, br, br, br, br, br }
}

-- 
function drawProgressBar(x, y, length, numItems, maxItems)
    local percentFull = numItems / maxItems
    local filledLength = math.floor(percentFull * length)

    -- Draw the filled part of the bar
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(colors.red)
    monitor.write(string.rep(" ", filledLength))

    -- Draw the unfilled part of the bar
    monitor.setBackgroundColor(colors.black)
    monitor.write(string.rep(" ", length - filledLength))

    -- Reset background color
    monitor.setBackgroundColor(colors.black)

end

-- 
function drawHappyFace(x, y)
    monitor.setCursorPos(x, y)
    monitor.write("  O  O  ")
    
    monitor.setCursorPos(x, y + 1)
    monitor.write("    >   ")
    
    monitor.setCursorPos(x, y + 2)
    monitor.write("  \\__/  ")
    return y + 3
end

-- 
local function write(x, y, text)
    monitor.setCursorPos(x, y)
    monitor.write(text)
    return y + 1
end

--
function displayBar(x, y, numItems, maxItems)

    -- Write the storage percentage
    local dText = "Storage is " .. string.format("%.2f", (numItems / maxItems) * 100) .. "% full"
    y = write(x, y, dText)

    -- Draw the progress bar
    drawProgressBar(x + 1, y, 20, numItems, maxItems)
    y = y + 1

    -- Write the item count
    y = write(x, y, "(" .. numItems .. "/" .. maxItems .. " items)")

    return y
end

--
function lib.displayManager(numItems, maxItems)
    monitor.setTextScale(0.5)

    local cursorY = 1
    monitor.clear()
    monitor.setBackgroundColor(colors.black)

    cursorY = displayBar(1, cursorY, numItems, maxItems)

    cursorY = write(1, cursorY, "The Cake is a lie")

    cursorY = drawPixels( 4, cursorY, cakePixelGrid)
    
    -- monitor.setTextScale(2)

    cursorY = write(1, cursorY, "this is a WIP.") 
    
    cursorY = drawHappyFace(3, cursorY)

end

-- Example usage:
-- local numItems = 840  -- Example number of items
-- local maxItems = 1728  -- Example maximum capacity

-- displayBar(numItems, maxItems)

return lib