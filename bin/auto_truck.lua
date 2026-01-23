--[[
auto_truck.lua - Automated trucking script for CC:Tweaked

Reads a truck_path.json config file and executes the defined tasks in a loop.
Handles fuel management and inventory clearing between tasks.

CONFIG FILE: ./truck_path.json (in turtle's root directory)

Example truck_path.json:
[
  {
    "Desc": "Move Kelp to Processing Network",
    "preSkip": "=kelp:64",
    "Commands": [
      "imv ../=kelp:++ ./",
      "mtk -m 'tltlmfmfmfmfmfmfmfmfmfmfmftrmfmfmftlmumumumu'",
      "imv ./=kelp:++ ../",
      "imv q:=kelp:bal:64",
      "mtk -m 'mdmdmdmdtlmfmfmftlmfmfmfmfmfmfmfmfmfmfmf'"
    ]
  },
  {
    "Desc": "Another Task",
    "Commands": []
  }
]

Task fields:
  Desc      - Description of the task
  Commands  - Array of commands to execute
  preSkip   - Optional. Format: "item:minCount". Skip task if fewer than
              minCount items matching pattern are on the network.
              Example: "=kelp:64" skips if less than 64 kelp available.

USAGE:
  auto_truck              -- Run once through all tasks
  auto_truck -l           -- Loop forever
  auto_truck -l 5         -- Loop 5 times
  auto_truck -v           -- Verbose output
  auto_truck -c <path>    -- Use custom config file path

FEATURES:
  - Clears inventory to network after each task
  - Checks fuel between tasks, refuels with lava bucket if below 1000
  - Skips tasks with empty command lists
]]

local CONFIG_PATH = "./truck_path.json"
local FUEL_THRESHOLD = 1000
local DEBUG = false

-- Load imv for preSkip queries
local imv = require("imv")

local function debugLog(...)
    if not DEBUG then return end
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        parts[i] = tostring(v)
    end
    local msg = "[" .. os.date("%H:%M:%S") .. "] " .. table.concat(parts, " ")
    print("[DEBUG] " .. msg)
end

local function crashOnError(msg)
    debugLog("FATAL ERROR:", msg)
    if DEBUG then
        error(msg, 2)
    end
end

-- Parse preSkip condition: "item:minCount" (e.g., "=kelp:64")
-- Returns: itemPattern, minCount or nil, nil if invalid
local function parsePreSkip(preSkip)
    if not preSkip or type(preSkip) ~= "string" then
        return nil, nil
    end
    local item, countStr = preSkip:match("^([^:]+):(%d+)$")
    if item and countStr then
        return item, tonumber(countStr)
    end
    return nil, nil
end

-- Check if preSkip condition is met (returns true if task should run)
local function checkPreSkip(preSkip)
    local item, minCount = parsePreSkip(preSkip)
    if not item then
        return true  -- No valid preSkip, run the task
    end

    debugLog("preSkip check: need", minCount, "of", item)
    local count = imv.queryCount(item)
    debugLog("preSkip check: found", count)

    if count >= minCount then
        return true  -- Enough items, run the task
    else
        return false, count, minCount  -- Not enough, skip
    end
end

-- Parse command line arguments
local function parseArgs(args)
    local config = {
        loop = false,
        loopCount = nil,
        verbose = false,
        configPath = CONFIG_PATH,
        debug = false
    }

    local i = 1
    while i <= #args do
        local arg = args[i]
        if arg == "-l" or arg == "--loop" then
            config.loop = true
            -- Check if next arg is a number
            if args[i + 1] and tonumber(args[i + 1]) then
                i = i + 1
                config.loopCount = tonumber(args[i])
            end
        elseif arg == "-v" or arg == "--verbose" then
            config.verbose = true
        elseif arg == "-d" or arg == "--debug" then
            config.debug = true
        elseif arg == "-c" or arg == "--config" then
            i = i + 1
            config.configPath = args[i]
        elseif arg == "-h" or arg == "--help" then
            config.help = true
        end
        i = i + 1
    end

    return config
end

-- Print usage
local function printUsage()
    print("Usage: auto_truck [-l [count]] [-v] [-d] [-c <path>]")
    print("")
    print("Options:")
    print("  -l, --loop [n]   Loop forever, or n times")
    print("  -v, --verbose    Verbose output")
    print("  -d, --debug      Debug mode (crash on error)")
    print("  -c, --config     Custom config file path")
    print("  -h, --help       Show this help")
    print("")
    print("Config: " .. CONFIG_PATH)
end

-- Load and parse JSON config
local function loadConfig(path)
    if not fs.exists(path) then
        return nil, "Config file not found: " .. path
    end

    local file = fs.open(path, "r")
    if not file then
        return nil, "Could not open config file: " .. path
    end

    local content = file.readAll()
    file.close()

    -- Parse JSON using textutils
    local ok, data = pcall(textutils.unserialiseJSON, content)
    if not ok or not data then
        return nil, "Failed to parse JSON: " .. tostring(data)
    end

    return data, nil
end

-- Clear inventory to network
local function clearInventory()
    print("  Clearing inventory...")
    debugLog("clearInventory() - running: imv ./*:++ ../")
    local success = shell.run("imv", "./*:++", "../")
    debugLog("clearInventory() - shell.run returned:", tostring(success))
    if not success then
        crashOnError("clearInventory failed: imv ./*:++ ../")
    end
end

-- Check and refuel if needed
local function checkFuel()
    debugLog("checkFuel()")
    local fuelLevel = turtle.getFuelLevel()
    debugLog("  fuelLevel:", tostring(fuelLevel))

    if fuelLevel == "unlimited" then
        print("  Fuel: unlimited")
        return true
    end

    print("  Fuel: " .. fuelLevel)

    if fuelLevel >= FUEL_THRESHOLD then
        debugLog("  Fuel OK, threshold:", FUEL_THRESHOLD)
        return true
    end

    print("  Fuel low, refueling...")
    debugLog("  Fuel below threshold, attempting refuel")

    -- Get lava bucket from network
    print("    Getting lava bucket from network...")
    debugLog("  Running: imv ../lava_bucket:1 ./")
    local success = shell.run("imv", "../lava_bucket:1", "./")
    debugLog("  shell.run returned:", tostring(success))

    -- Find and use the lava bucket
    local refueled = false
    debugLog("  Scanning inventory for lava bucket...")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            debugLog("    Slot", slot, ":", item.name)
            if item.name:find("lava") then
                debugLog("    Found lava in slot", slot)
                turtle.select(slot)
                if turtle.refuel() then
                    print("    Refueled to " .. turtle.getFuelLevel())
                    debugLog("    Refuel successful, new level:", turtle.getFuelLevel())
                    refueled = true
                    break
                else
                    debugLog("    turtle.refuel() returned false")
                end
            end
        end
    end

    if not refueled then
        print("    Warning: Could not refuel (no lava bucket found)")
        debugLog("  Refuel FAILED - no lava bucket found")
    end

    -- Clear any leftover items (empty bucket, etc)
    clearInventory()
    return refueled
end

-- Execute a single command
local function executeCommand(cmd, verbose)
    debugLog("executeCommand('" .. cmd .. "')")
    if verbose then
        print("    > " .. cmd)
    end

    -- Parse the command into program and arguments
    local parts = {}
    -- Handle quoted strings
    local inQuote = false
    local quoteChar = nil
    local current = ""

    for i = 1, #cmd do
        local c = cmd:sub(i, i)
        if not inQuote and (c == '"' or c == "'") then
            inQuote = true
            quoteChar = c
        elseif inQuote and c == quoteChar then
            inQuote = false
            quoteChar = nil
        elseif not inQuote and c == " " then
            if #current > 0 then
                table.insert(parts, current)
                current = ""
            end
        else
            current = current .. c
        end
    end
    if #current > 0 then
        table.insert(parts, current)
    end

    if #parts == 0 then
        debugLog("  Empty command, skipping")
        return true
    end

    local program = parts[1]
    local args = {table.unpack(parts, 2)}

    -- Normalize program path
    -- Remove leading /bin/ or bin/ if present, shell.run will find it
    program = program:gsub("^/bin/", ""):gsub("^bin/", "")
    -- Remove .lua extension if present
    program = program:gsub("%.lua$", "")

    debugLog("  Program:", program)
    debugLog("  Args:", table.concat(args, ", "))

    -- Execute via shell.run
    local success = shell.run(program, table.unpack(args))
    debugLog("  shell.run returned:", tostring(success))

    if not success then
        if verbose then
            print("    Command returned false/nil")
        end
        crashOnError("Command failed: " .. cmd)
    end

    return success
end

-- Execute a single task
local function executeTask(task, taskNum, verbose)
    local desc = task.Desc or task.desc or ("Task " .. taskNum)
    local commands = task.Commands or task.commands or {}
    local preSkip = task.preSkip or task.PreSkip

    debugLog("executeTask(", taskNum, ",", desc, ") -", #commands, "commands")

    -- Skip empty tasks
    if #commands == 0 then
        debugLog("  Skipping empty task")
        if verbose then
            print("Skipping empty task: " .. desc)
        end
        return true, "empty"
    end

    -- Check preSkip condition
    if preSkip then
        local shouldRun, found, needed = checkPreSkip(preSkip)
        if not shouldRun then
            print("Skipping task " .. taskNum .. ": " .. desc .. " (need " .. needed .. " items, found " .. found .. ")")
            return true, "skipped"
        end
    end

    print("Task " .. taskNum .. ": " .. desc)

    -- Execute each command
    for i, cmd in ipairs(commands) do
        debugLog("  Command", i, "of", #commands)
        if not executeCommand(cmd, verbose) then
            print("  Warning: Command " .. i .. " failed")
            debugLog("  Command", i, "FAILED")
            -- crashOnError is called inside executeCommand if DEBUG is on
        end
    end

    debugLog("  Task completed")
    return true, "completed"
end

-- Main loop
local function run(config)
    -- Enable debug mode if requested
    if config.debug then
        DEBUG = true
        debugLog("=== AUTO_TRUCK DEBUG MODE ===")
        debugLog("Config path:", config.configPath)
        debugLog("Loop:", tostring(config.loop), "Count:", tostring(config.loopCount))
    end

    local tasks, err = loadConfig(config.configPath)
    if not tasks then
        print("Error: " .. err)
        crashOnError("Failed to load config: " .. err)
        return false
    end

    debugLog("Loaded", #tasks, "tasks")

    if #tasks == 0 then
        print("No tasks defined in config")
        return true
    end

    print("Loaded " .. #tasks .. " tasks from " .. config.configPath)

    local iteration = 0
    local maxIterations = config.loopCount

    repeat
        iteration = iteration + 1

        if config.loop then
            if maxIterations then
                print(string.format("\n=== Iteration %d/%d ===", iteration, maxIterations))
            else
                print(string.format("\n=== Iteration %d ===", iteration))
            end
        end

        for taskNum, task in ipairs(tasks) do
            debugLog("=== Starting task", taskNum, "of", #tasks, "===")

            -- Execute the task
            local success, status = executeTask(task, taskNum, config.verbose)

            -- Only do post-task cleanup if task actually ran
            if status == "completed" then
                -- Clear inventory after task
                debugLog("Post-task: clearing inventory")
                clearInventory()

                -- Check fuel after clearing (for next task)
                debugLog("Post-task: checking fuel")
                checkFuel()
            end

            debugLog("=== Finished task", taskNum, "(", status, ") ===")
        end

        -- Check if we should continue looping
        if not config.loop then
            break
        end

        if maxIterations and iteration >= maxIterations then
            break
        end

        -- Small delay between iterations
        os.sleep(1)

    until false

    print("\nAll tasks completed")
    return true
end

-- CLI entry point
local function main(args)
    local config = parseArgs(args)

    if config.help then
        printUsage()
        return
    end

    run(config)
end

-- Run if executed directly
local args = {...}
if #args > 0 or shell then
    main(args)
end
