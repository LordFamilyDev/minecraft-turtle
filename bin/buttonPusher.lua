local args = {...}

-- Default values
local pulseTime = 0.1  -- 100ms
local rate = 0.1       -- 100ms
local triggerDir = "front"
local outputDir = "front"
local triggerType = "continuous"  -- Default to continuous mode

-- Function to parse arguments
local function parseArgs()
    for i = 1, #args do
        if args[i] == "--pulseTime" and args[i+1] then
            pulseTime = tonumber(args[i+1]) / 1000  -- Convert ms to seconds
        elseif args[i] == "--rate" and args[i+1] then
            rate = tonumber(args[i+1]) / 1000  -- Convert ms to seconds
        elseif args[i] == "--trigger" and args[i+1] then
            triggerDir = args[i+1]
        elseif args[i] == "--output" and args[i+1] then
            outputDir = args[i+1]
        elseif args[i] == "--triggerType" and args[i+1] then
            triggerType = args[i+1]
        end
    end
end

-- Parse command-line arguments
parseArgs()

-- Get the peripheral in the specified direction
local inv = peripheral.wrap(triggerDir)

print("Checker started with settings:")
print("Pulse Time: " .. pulseTime * 1000 .. "ms")
print("Rate: " .. rate * 1000 .. "ms")
print("Trigger Direction: " .. triggerDir)
print("Output Direction: " .. outputDir)
print("Trigger Type: " .. triggerType)

local function checkTriggerCondition()
    if triggerType == "inventory" then
        -- Check if the peripheral is an inventory
        if inv and inv.list then
            local items = inv.list()
            return #items > 0
        end
    elseif triggerType == "redstone" then
        -- Check for redstone signal
        return redstone.getInput(triggerDir)
    elseif triggerType == "continuous" then
        -- Always return true for continuous mode
        return true
    end
    return false
end

while true do
    local shouldTrigger = checkTriggerCondition()
    
    if shouldTrigger then
        redstone.setOutput(outputDir, true)
        os.sleep(pulseTime)
        redstone.setOutput(outputDir, false)
    end
    
    os.sleep(rate - pulseTime)  -- Ensure total cycle time is equal to rate
end