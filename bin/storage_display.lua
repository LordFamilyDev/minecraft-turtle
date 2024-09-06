-- storage_display.lua

-- Import libraries
local lib_ui = require("/lib/lib_ui")
local simple_storage = require("/lib/lib_user_storage")

-- Infinite loop to continuously update the display
while true do
    -- Get the storage utilization
    local used, total = simple_storage.getStorageUtilization()
    
    -- Update the UI with the current storage values
    lib_ui.displayManager(used, total)
    
    -- Sleep for 3 seconds before updating again
    sleep(3)
end

-- -- to run in background
-- bg /bin/storage_display.lua
-- -- to find background jobs
-- jobs
-- -- View job
-- fg <taskID>
-- -- Kill backgroun job
-- kill <taskID>



