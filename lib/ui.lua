local monitor = peripheral.wrap("monitor_4")  -- Replace "right" with the side your monitor is on

function drawProgressBar(monitor, x, y, length, numItems, maxItems)
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

function drawHappyFace(x, y)
    monitor.setCursorPos(x, y)
    monitor.write("  O  O  ")
    
    monitor.setCursorPos(x, y + 1)
    monitor.write("    >   ")
    
    monitor.setCursorPos(x, y + 2)
    monitor.write("  \\__/  ")
end

function drawCake(x, y)
    monitor.setCursorPos(x, y)
    monitor.write("  [ ==== ]   ")
    
    monitor.setCursorPos(x, y + 1)
    monitor.write("  | CAKE |  ")
    
    monitor.setCursorPos(x, y + 2)
    monitor.write("  [ ==== ]   ")
end

function displayBar(numItems, maxItems)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Chest is " .. string.format("%.2f", (numItems / maxItems) * 100) .. "% full")
    monitor.setCursorPos(2, 2)
    drawProgressBar(monitor, 2, 2, 20, numItems, maxItems)
    monitor.setCursorPos(1, 3)
    monitor.write("(" .. numItems .. "/" .. maxItems .. " items)")
    monitor.setCursorPos(1, 4)
    monitor.write("The Cake is a lie")
    monitor.setCursorPos(2, 5)
    drawCake(4, 5)
    monitor.setCursorPos(1, 8)
    monitor.write("this is a WIP.")
    monitor.setCursorPos(2, 9)
    drawHappyFace(3, 9)

end

-- Example usage:
local numItems = 840  -- Example number of items
local maxItems = 1728  -- Example maximum capacity

displayBar(numItems, maxItems)
