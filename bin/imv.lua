--[[
imv.lua - Item Move utility for CC:Tweaked

A flexible item transfer utility for moving items between inventories
on a wired modem network. Supports fuzzy matching for both locations
and item names. Also supports querying the network for item counts
and balancing items between inventories.

COMMAND LINE USAGE:
  imv [-v] <source> <destination>
  imv [-v] q:<item>:<mode>

MOVE PATTERN FORMAT:
  <location>/<item>:<count>

  location: peripheral name, fuzzy match (chest23), ./ (self), * or ../ (any)
  item:     item name or fuzzy match, =name for exact match (defaults to *)
  count:    number, * or + for one full stack, ++ for ALL matching items (defaults to 1)

QUERY PATTERN FORMAT:
  q:<item>:<mode>
  q:<item>:bal:<limit>

  item:   item name or fuzzy match pattern
  mode:   count | high | low | bal
    count: returns total count of item across all inventories
    high:  returns name of inventory with most of that item
    low:   returns name of inventory with least of that item (>0)
    bal:   distributes items evenly across all chests (total / numChests)
  limit:  (optional, bal only) keep balancing until amount moved < limit

MOVE EXAMPLES:
  imv chest23/lava:1 ./        -- 1 lava from chest23 to self
  imv ./coal:* chest23         -- full stack of coal from self to chest23
  imv */diamond:+ ./           -- full stack of diamonds from anywhere to self
  imv ./lava:1 ../             -- 1 lava from self to any available chest
  imv */=bucket:1 ./           -- 1 empty bucket (exact match, not lava_bucket)
  imv ./*:++ ../               -- ALL items from self to any available chest

QUERY EXAMPLES:
  imv q:diamond:count          -- total diamonds on network
  imv q:coal:high              -- chest with most coal
  imv q:iron:low               -- chest with least iron (>0)
  imv -v q:gold:bal            -- distribute gold evenly across all chests
  imv -v q:coal:bal:10         -- keep balancing until <10 moved per pass

LIBRARY USAGE:
  local imv = require("imv")

  -- High-level move (same as CLI)
  local count, err = imv.move("chest23/lava:1", "./")
  local count, err = imv.move("./coal:*", "chest23", {verbose = true})

  -- Query functions
  local total = imv.queryCount("diamond")           -- total diamonds on network
  local inv, count = imv.queryHigh("coal")          -- inventory with most coal
  local inv, count = imv.queryLow("iron")           -- inventory with least iron (>0)
  local moved, err = imv.queryBalance("gold")       -- balance gold between inventories

  -- Get turtle's network name
  local name = imv.getLocalName()  -- e.g., "turtle_6"

  -- Get all inventory peripherals on network
  local invs = imv.getAllInventories()  -- {"minecraft:chest_1", ...}

  -- Fuzzy match a location pattern
  local names, isAnyMode = imv.matchLocation("chest23")

  -- Parse a pattern string
  local location, item, count = imv.parsePattern("chest23/coal:10")

  -- Find items in an inventory
  local items = imv.findItems("minecraft:chest_23", "coal")
  -- Returns: {{slot=1, name="minecraft:coal", count=64, maxCount=64}, ...}

  -- Low-level transfer between specific slots
  local transferred = imv.transfer("minecraft:chest_23", 1, "turtle_6", 10)

API REFERENCE:

  imv.getLocalName()
    Returns the turtle's network name (e.g., "turtle_6") or nil

  imv.getAllInventories()
    Returns a list of all inventory peripheral names on the network

  imv.matchLocation(pattern)
    Fuzzy-matches a location pattern against available peripherals
    Returns: names (table), isAnyMode (boolean)

  imv.parsePattern(str)
    Parses a pattern like "chest23/coal:10" or "./lava:*"
    Returns: location (string), item (string), count (number|"max")

  imv.findItems(invName, itemPattern)
    Finds items matching pattern in the specified inventory
    Returns: {{slot, name, count, maxCount}, ...}

  imv.transfer(srcName, srcSlot, dstName, count)
    Transfers items between two inventory slots
    Returns: number of items transferred

  imv.move(srcPattern, dstPattern, opts)
    High-level move matching CLI behavior
    opts.verbose: print transfer details (default: false)
    Returns: totalTransferred (number), errorMsg (string|nil)

  imv.queryCount(itemPattern)
    Counts total items matching pattern across all network inventories
    Returns: total (number)

  imv.queryHigh(itemPattern)
    Finds inventory with the most items matching pattern
    Returns: invName (string|nil), count (number)

  imv.queryLow(itemPattern)
    Finds inventory with the least items matching pattern (but >0)
    Returns: invName (string|nil), count (number)

  imv.queryLowIncludeEmpty(itemPattern)
    Finds inventory with the least items matching pattern (including 0)
    Returns: invName (string|nil), count (number)

  imv.queryBalance(itemPattern, opts)
    Distributes items evenly across all inventories on the network
    Calculates target = total / numChests and moves to achieve even distribution
    opts.verbose: print transfer details (default: false)
    opts.limit: if set, keep looping until amount moved < limit
    Returns: totalItemsMoved (number), errorMsg (string|nil)
]]

local imv = {}

-- Debug mode
local DEBUG = false

local function debugLog(...)
    if not DEBUG then return end
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        parts[i] = tostring(v)
    end
    local msg = "[" .. os.date("%H:%M:%S") .. "] " .. table.concat(parts, " ")
    print(msg)
end

local function debugError(msg)
    debugLog("ERROR:", msg)
    if DEBUG then
        error(msg, 2)
    end
end

-- Sentinel value for local turtle (works even when disconnected from network)
local LOCAL_TURTLE = "__local_turtle__"

-- Enable debug mode
function imv.setDebug(enabled)
    DEBUG = enabled
    if enabled then
        debugLog("=== IMV DEBUG MODE ENABLED ===")
    end
end

-- Get local name (turtle's network name), or nil if not connected
-- Retries a few times with small delays to handle network initialization
function imv.getLocalName(retries)
    retries = retries or 3
    for attempt = 1, retries do
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "modem" then
                local modem = peripheral.wrap(name)
                if modem.getNameLocal then
                    local localName = modem.getNameLocal()
                    if localName then
                        debugLog("getLocalName() ->", localName, "(attempt", attempt .. ")")
                        return localName
                    end
                end
            end
        end
        if attempt < retries then
            debugLog("getLocalName() attempt", attempt, "failed, retrying...")
            os.sleep(0.2)
        end
    end
    debugLog("getLocalName() -> nil (not connected to network after", retries, "attempts)")
    return nil
end

-- Get all inventory peripherals
-- Retries if no inventories found (network may need time to initialize)
function imv.getAllInventories(retries)
    retries = retries or 3
    for attempt = 1, retries do
        local inventories = {}
        for _, name in ipairs(peripheral.getNames()) do
            local p = peripheral.wrap(name)
            if p and type(p.list) == "function" then
                table.insert(inventories, name)
            end
        end
        if #inventories > 0 then
            debugLog("getAllInventories() found", #inventories, "inventories (attempt", attempt .. ")")
            return inventories
        end
        if attempt < retries then
            debugLog("getAllInventories() found 0 inventories, retrying...")
            os.sleep(0.2)
        end
    end
    debugLog("getAllInventories() -> empty (no inventories found after retries)")
    return {}
end

-- Fuzzy match a pattern against peripheral names
function imv.matchLocation(pattern)
    debugLog("matchLocation('" .. tostring(pattern) .. "')")

    if pattern == "./" or pattern == "." then
        -- Use sentinel for local turtle (works even when disconnected)
        debugLog("  -> LOCAL_TURTLE (self)")
        return {LOCAL_TURTLE}, false
    end

    if pattern == "*" or pattern == "../" or pattern == ".." then
        local invs = imv.getAllInventories()
        debugLog("  -> any mode, found", #invs, "inventories")
        return invs, true  -- true = "any" mode
    end

    local names = peripheral.getNames()
    local matches = {}

    -- Exact match first
    for _, name in ipairs(names) do
        if name == pattern then
            return {name}, false
        end
    end

    -- Normalize pattern for fuzzy matching
    -- "chest23" should match "minecraft:chest_23"
    local normalizedPattern = pattern:lower()

    for _, name in ipairs(names) do
        local normalizedName = name:lower()

        -- Direct substring match
        if normalizedName:find(normalizedPattern, 1, true) then
            table.insert(matches, name)
        else
            -- Try matching with underscores/colons removed
            local simpleName = normalizedName:gsub("[_:]", "")
            local simplePattern = normalizedPattern:gsub("[_:]", "")
            if simpleName:find(simplePattern, 1, true) then
                table.insert(matches, name)
            end
        end
    end

    -- Sort matches by length (prefer shorter/more specific matches)
    table.sort(matches, function(a, b) return #a < #b end)

    if #matches > 0 then
        return {matches[1]}, false
    end

    return {}, false
end

-- Parse a pattern like "chest23/lava:5" or "./coal" or just "chest23"
-- Supports both / and \ as separators
function imv.parsePattern(str)
    -- Normalize: replace \ with /
    str = str:gsub("\\", "/")

    -- Handle special cases: ./ ../ or * alone as location
    if str == "./" or str == "." or str == "../" or str == ".." or str == "*" then
        return str, "*", 1
    end

    -- Check for separator (now only /)
    -- Pattern: location/item:count or location/item or just location
    local location, rest = str:match("^(.-)/([^/]+)$")

    if not location or location == "" then
        -- No valid separator found, treat whole thing as location
        return str, "*", 1
    end

    -- Parse item:count from rest
    local item, countStr = rest:match("^([^:]+):?([%d%*%+]*)$")
    local count
    if countStr == "++" then
        count = "all"  -- sentinel: transfer ALL matching items
    elseif countStr == "*" or countStr == "+" then
        count = "max"  -- sentinel: use item's maxCount (one stack)
    else
        count = tonumber(countStr) or 1
    end

    return location, item or "*", count
end

-- Check if a name matches the local turtle
local function isLocalTurtle(name)
    if name == LOCAL_TURTLE then
        return true
    end
    local localName = imv.getLocalName()
    return localName and name == localName
end

-- Check if item name matches pattern
-- Supports exact match with = prefix (e.g., =minecraft:bucket or =bucket)
local function itemMatches(itemName, itemPattern)
    if itemPattern == "*" then
        return true
    end

    local normalizedName = itemName:lower()

    -- Exact match mode: pattern starts with =
    if itemPattern:sub(1, 1) == "=" then
        local exactPattern = itemPattern:sub(2):lower()
        -- Match full name or short name (without namespace)
        local shortName = normalizedName:gsub("^[^:]+:", "")
        return normalizedName == exactPattern or shortName == exactPattern
    end

    -- Fuzzy match mode (default)
    local normalizedPattern = itemPattern:lower()

    if normalizedName:find(normalizedPattern, 1, true) then
        return true
    end

    -- Try without namespace
    local shortName = normalizedName:gsub("^[^:]+:", "")
    if shortName:find(normalizedPattern, 1, true) then
        return true
    end

    return false
end

-- Find items matching pattern in an inventory
function imv.findItems(invName, itemPattern)
    debugLog("findItems('" .. tostring(invName) .. "', '" .. tostring(itemPattern) .. "')")
    local results = {}

    -- Special case: local turtle inventory
    if isLocalTurtle(invName) then
        debugLog("  Scanning local turtle inventory")
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and itemMatches(item.name, itemPattern) then
                debugLog("    Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
                table.insert(results, {
                    slot = slot,
                    name = item.name,
                    count = item.count,
                    maxCount = item.maxCount or 64
                })
            end
        end
        debugLog("  Found " .. #results .. " matching items in local turtle")
        return results
    end

    -- Remote inventory via peripheral
    local inv = peripheral.wrap(invName)
    if not inv or not inv.list then
        return {}
    end

    local ok, items = pcall(function() return inv.list() end)
    if not ok then return {} end

    for slot, item in pairs(items) do
        if itemMatches(item.name, itemPattern) then
            -- Get detailed info for maxCount
            local detail = inv.getItemDetail and inv.getItemDetail(slot)
            local maxCount = (detail and detail.maxCount) or 64
            table.insert(results, {
                slot = slot,
                name = item.name,
                count = item.count,
                maxCount = maxCount
            })
        end
    end

    return results
end

-- Transfer items between inventories
function imv.transfer(srcName, srcSlot, dstName, count)
    debugLog("transfer(src=" .. tostring(srcName) .. ", slot=" .. tostring(srcSlot) .. ", dst=" .. tostring(dstName) .. ", count=" .. tostring(count) .. ")")

    if isLocalTurtle(srcName) then
        debugLog("  Source is local turtle")
        -- Source is local turtle, destination must pull from us
        local dstInv = peripheral.wrap(dstName)
        if not dstInv then
            debugLog("  ERROR: Could not wrap destination peripheral:", dstName)
            debugError("Could not wrap destination peripheral: " .. tostring(dstName))
            return 0
        end
        if not dstInv.pullItems then
            debugLog("  ERROR: Destination has no pullItems method:", dstName)
            debugError("Destination has no pullItems method: " .. tostring(dstName))
            return 0
        end
        -- Get current network name (may differ between networks)
        local localName = imv.getLocalName()
        if not localName then
            debugLog("  ERROR: Not connected to network, can't transfer")
            debugError("Not connected to network, can't transfer from local turtle")
            return 0
        end
        debugLog("  Calling pullItems('" .. localName .. "', " .. srcSlot .. ", " .. count .. ")")
        local ok, result = pcall(function()
            return dstInv.pullItems(localName, srcSlot, count)
        end)
        if not ok then
            debugLog("  ERROR: pullItems failed:", result)
            debugError("pullItems failed: " .. tostring(result))
            return 0
        end
        debugLog("  Transferred:", result)
        return result or 0

    elseif isLocalTurtle(dstName) then
        debugLog("  Destination is local turtle")
        -- Destination is local turtle, source must push to us
        local srcInv = peripheral.wrap(srcName)
        if not srcInv then
            debugLog("  ERROR: Could not wrap source peripheral:", srcName)
            debugError("Could not wrap source peripheral: " .. tostring(srcName))
            return 0
        end
        if not srcInv.pushItems then
            debugLog("  ERROR: Source has no pushItems method:", srcName)
            debugError("Source has no pushItems method: " .. tostring(srcName))
            return 0
        end
        local localName = imv.getLocalName()
        if not localName then
            debugLog("  ERROR: Not connected to network, can't transfer")
            debugError("Not connected to network, can't transfer to local turtle")
            return 0
        end
        debugLog("  Calling pushItems('" .. localName .. "', " .. srcSlot .. ", " .. count .. ")")
        local ok, result = pcall(function()
            return srcInv.pushItems(localName, srcSlot, count)
        end)
        if not ok then
            debugLog("  ERROR: pushItems failed:", result)
            debugError("pushItems failed: " .. tostring(result))
            return 0
        end
        debugLog("  Transferred:", result)
        return result or 0

    else
        debugLog("  Remote to remote transfer")
        -- Source is remote, it pushes to destination
        local srcInv = peripheral.wrap(srcName)
        if not srcInv then
            debugLog("  ERROR: Could not wrap source peripheral:", srcName)
            debugError("Could not wrap source peripheral: " .. tostring(srcName))
            return 0
        end
        if not srcInv.pushItems then
            debugLog("  ERROR: Source has no pushItems method:", srcName)
            debugError("Source has no pushItems method: " .. tostring(srcName))
            return 0
        end
        debugLog("  Calling pushItems('" .. dstName .. "', " .. srcSlot .. ", " .. count .. ")")
        local ok, result = pcall(function()
            return srcInv.pushItems(dstName, srcSlot, count)
        end)
        if not ok then
            debugLog("  ERROR: pushItems failed:", result)
            debugError("pushItems failed: " .. tostring(result))
            return 0
        end
        debugLog("  Transferred:", result)
        return result or 0
    end
end

-- High-level move function
-- Returns: totalTransferred, errorMsg
function imv.move(srcPattern, dstPattern, opts)
    opts = opts or {}
    local verbose = opts.verbose or false

    debugLog("move('" .. tostring(srcPattern) .. "', '" .. tostring(dstPattern) .. "')")

    local srcLoc, srcItem, srcCount = imv.parsePattern(srcPattern)
    local dstLoc, dstItem, dstCount = imv.parsePattern(dstPattern)
    debugLog("  Parsed src: loc=" .. tostring(srcLoc) .. ", item=" .. tostring(srcItem) .. ", count=" .. tostring(srcCount))
    debugLog("  Parsed dst: loc=" .. tostring(dstLoc) .. ", item=" .. tostring(dstItem) .. ", count=" .. tostring(dstCount))

    -- Resolve locations
    local srcNames, srcAnyMode = imv.matchLocation(srcLoc)
    local dstNames, dstAnyMode = imv.matchLocation(dstLoc)

    debugLog("  srcNames:", #srcNames, "srcAnyMode:", tostring(srcAnyMode))
    debugLog("  dstNames:", #dstNames, "dstAnyMode:", tostring(dstAnyMode))

    if #srcNames == 0 then
        local err = "Could not find source location: " .. srcLoc
        debugLog("  ERROR:", err)
        debugError(err)
        return 0, err
    end

    if #dstNames == 0 then
        local err = "Could not find destination location: " .. dstLoc
        debugLog("  ERROR:", err)
        debugError(err)
        return 0, err
    end

    -- For non-any destination mode, only allow single destination
    if not dstAnyMode and #dstNames > 1 then
        return 0, "Destination must be a single location, matched: " .. #dstNames
    end

    local totalTransferred = 0
    local remaining = srcCount  -- may be "max", "all", or a number
    local destinationFull = false

    -- Search through all source locations
    for _, srcName in ipairs(srcNames) do
        if type(remaining) == "number" and remaining <= 0 then break end
        if destinationFull then break end

        local items = imv.findItems(srcName, srcItem)

        if #items > 0 then
            for _, item in ipairs(items) do
                if type(remaining) == "number" and remaining <= 0 then break end
                if destinationFull then break end

                -- Calculate how many to transfer
                local toTransfer
                if remaining == "all" then
                    toTransfer = item.count  -- transfer entire stack, continue to next
                elseif remaining == "max" then
                    toTransfer = math.min(item.maxCount, item.count)
                    remaining = toTransfer  -- convert to number for tracking (one stack only)
                else
                    toTransfer = math.min(remaining, item.count)
                end

                if dstAnyMode then
                    -- Try each destination until we successfully transfer
                    local transferredAny = false
                    for _, dstName in ipairs(dstNames) do
                        if dstName ~= srcName and toTransfer > 0 then
                            local ok, transferred = pcall(function()
                                return imv.transfer(srcName, item.slot, dstName, toTransfer)
                            end)

                            if ok and transferred and transferred > 0 then
                                totalTransferred = totalTransferred + transferred
                                if type(remaining) == "number" then
                                    remaining = remaining - transferred
                                end
                                toTransfer = toTransfer - transferred
                                transferredAny = true
                                if verbose then
                                    print(string.format("%s: %d x %s -> %s", srcName, transferred, item.name, dstName))
                                end
                            end
                        end
                        if toTransfer <= 0 then break end
                    end
                    -- If we couldn't transfer to ANY destination in "all" mode, network is full
                    if remaining == "all" and not transferredAny and toTransfer > 0 then
                        debugLog("All destinations full, stopping early")
                        destinationFull = true
                    end
                else
                    -- Single destination
                    local dstName = dstNames[1]
                    local ok, transferred = pcall(function()
                        return imv.transfer(srcName, item.slot, dstName, toTransfer)
                    end)

                    if ok and transferred and transferred > 0 then
                        totalTransferred = totalTransferred + transferred
                        if type(remaining) == "number" then
                            remaining = remaining - transferred
                        end
                        if verbose then
                            print(string.format("%s: %d x %s -> %s", srcName, transferred, item.name, dstName))
                        end
                        -- If we transferred less than requested in "all" mode, destination is full
                        if remaining == "all" and transferred < toTransfer then
                            debugLog("Destination full (transferred", transferred, "of", toTransfer, "), stopping early")
                            destinationFull = true
                        end
                    elseif remaining == "all" and toTransfer > 0 then
                        -- Requested transfer but got nothing - destination full
                        debugLog("Destination full (0 transferred), stopping early")
                        destinationFull = true
                    end
                end
            end
        end
    end

    if totalTransferred == 0 then
        return 0, "No items matching '" .. srcItem .. "' found or destination full"
    end

    if verbose then
        print(string.format("Total: %d items transferred", totalTransferred))
    end

    -- Fire turtle_inventory event if local turtle was involved (as source or destination)
    local localName = imv.getLocalName()
    if localName then
        for _, name in ipairs(srcNames) do
            if name == localName then
                os.queueEvent("turtle_inventory")
                break
            end
        end
        for _, name in ipairs(dstNames) do
            if name == localName then
                os.queueEvent("turtle_inventory")
                break
            end
        end
    end

    return totalTransferred, nil
end

-- Query: count total items matching pattern across all inventories
function imv.queryCount(itemPattern)
    local inventories = imv.getAllInventories()
    local total = 0

    for _, invName in ipairs(inventories) do
        local items = imv.findItems(invName, itemPattern)
        for _, item in ipairs(items) do
            total = total + item.count
        end
    end

    return total
end

-- Query: find inventory with most/least of an item
-- Returns: invName, count (or nil, 0 if not found)
-- opts.includeEmpty: if true, include inventories with 0 of the item (for low search)
function imv.queryHighLow(itemPattern, findHigh, opts)
    opts = opts or {}
    local includeEmpty = opts.includeEmpty or false
    local inventories = imv.getAllInventories()
    local bestInv = nil
    local bestCount = findHigh and -1 or math.huge

    for _, invName in ipairs(inventories) do
        local items = imv.findItems(invName, itemPattern)
        local invTotal = 0
        for _, item in ipairs(items) do
            invTotal = invTotal + item.count
        end

        if invTotal > 0 or (not findHigh and includeEmpty) then
            if findHigh and invTotal > bestCount then
                bestCount = invTotal
                bestInv = invName
            elseif not findHigh and invTotal < bestCount then
                bestCount = invTotal
                bestInv = invName
            end
        end
    end

    if bestInv then
        return bestInv, bestCount
    end
    return nil, 0
end

-- Query: find inventory with the most of an item
function imv.queryHigh(itemPattern)
    return imv.queryHighLow(itemPattern, true)
end

-- Query: find inventory with the least of an item (but > 0)
function imv.queryLow(itemPattern)
    return imv.queryHighLow(itemPattern, false)
end

-- Query: find inventory with the least of an item (including 0)
function imv.queryLowIncludeEmpty(itemPattern)
    return imv.queryHighLow(itemPattern, false, {includeEmpty = true})
end

-- Query: balance items evenly across all inventories on the network
-- Calculates target = total / numChests and moves items to achieve even distribution
-- opts.limit: if set, keep looping until amount moved < limit
-- Returns: itemsMoved, errorMsg
function imv.queryBalance(itemPattern, opts)
    opts = opts or {}
    local verbose = opts.verbose or false
    local limit = opts.limit

    -- Build inventory map
    local inventories = imv.getAllInventories()
    local numChests = #inventories

    if numChests == 0 then
        return 0, "No inventories on network"
    end

    -- Count items in each inventory
    local function countItems()
        local invCounts = {}
        local total = 0
        for _, invName in ipairs(inventories) do
            local items = imv.findItems(invName, itemPattern)
            local count = 0
            for _, item in ipairs(items) do
                count = count + item.count
            end
            invCounts[invName] = count
            total = total + count
        end
        return invCounts, total
    end

    local invCounts, total = countItems()

    if total == 0 then
        return 0, "No items matching '" .. itemPattern .. "' found"
    end

    local target = math.floor(total / numChests)
    local remainder = total % numChests

    -- Sort inventories by count descending
    -- Chests with more items get target+1 (minimizes movement)
    table.sort(inventories, function(a, b)
        return invCounts[a] > invCounts[b]
    end)

    -- Assign targets: first 'remainder' chests get target+1, rest get target
    local targets = {}
    for i, invName in ipairs(inventories) do
        if i <= remainder then
            targets[invName] = target + 1
        else
            targets[invName] = target
        end
    end

    if verbose then
        print(string.format("Balancing %d %s across %d chests", total, itemPattern, numChests))
        print(string.format("Target: %d per chest", target))
        if remainder > 0 then
            print(string.format("  (%d chests get %d)", remainder, target + 1))
        end
    end

    local totalMoved = 0
    local iteration = 0

    repeat
        iteration = iteration + 1
        local movedThisIteration = 0

        -- Refresh counts
        invCounts = countItems()

        -- Build donor and receiver lists
        local donors = {}
        local receivers = {}

        for _, invName in ipairs(inventories) do
            local current = invCounts[invName]
            local targetCount = targets[invName]
            local diff = current - targetCount

            if diff > 0 then
                table.insert(donors, {name = invName, excess = diff, current = current})
            elseif diff < 0 then
                table.insert(receivers, {name = invName, need = -diff, current = current})
            end
        end

        if #donors == 0 or #receivers == 0 then
            break -- balanced
        end

        if verbose and (limit or iteration == 1) then
            print(string.format("--- Pass %d ---", iteration))
        end

        -- Move from donors to receivers
        for _, donor in ipairs(donors) do
            for _, receiver in ipairs(receivers) do
                if donor.excess > 0 and receiver.need > 0 then
                    local toMove = math.min(donor.excess, receiver.need)

                    if verbose then
                        print(string.format("  %s (%d) -> %s (%d): %d",
                            donor.name, donor.current,
                            receiver.name, receiver.current,
                            toMove))
                    end

                    local srcPattern = donor.name .. "/" .. itemPattern .. ":" .. toMove
                    local moved, _ = imv.move(srcPattern, receiver.name, {verbose = false})

                    if moved and moved > 0 then
                        donor.excess = donor.excess - moved
                        donor.current = donor.current - moved
                        receiver.need = receiver.need - moved
                        receiver.current = receiver.current + moved
                        movedThisIteration = movedThisIteration + moved
                        totalMoved = totalMoved + moved
                    end
                end
            end
        end

        -- Stop conditions
        if movedThisIteration == 0 then
            break
        end

        if not limit then
            break
        end

        if movedThisIteration < limit then
            break
        end

    until false

    if verbose then
        print(string.format("Total moved: %d", totalMoved))
    end

    return totalMoved, nil
end

-- Parse query pattern: q:<item>:<mode> or q:<item>:<mode>:<param>
local function parseQuery(str)
    -- Try with param first: q:item:mode:param
    local item, mode, param = str:match("^q:([^:]+):([^:]+):(.+)$")
    if item and mode then
        return item, mode:lower(), param
    end
    -- Try without param: q:item:mode
    item, mode = str:match("^q:([^:]+):([^:]+)$")
    if item and mode then
        return item, mode:lower(), nil
    end
    return nil, nil, nil
end

-- Handle query commands
local function handleQuery(item, mode, verbose, param)
    if mode == "count" then
        local total = imv.queryCount(item)
        print(total)
        return total
    elseif mode == "high" then
        local inv, count = imv.queryHigh(item)
        if inv then
            print(inv)
            if verbose then
                print(string.format("  (%d items)", count))
            end
            return inv
        else
            print("Not found")
            return nil
        end
    elseif mode == "low" then
        local inv, count = imv.queryLow(item)
        if inv then
            print(inv)
            if verbose then
                print(string.format("  (%d items)", count))
            end
            return inv
        else
            print("Not found")
            return nil
        end
    elseif mode == "bal" then
        local limit = param and tonumber(param)
        local moved, err = imv.queryBalance(item, {verbose = verbose, limit = limit})
        if err then
            print("Error: " .. err)
            return 0
        end
        print(moved)
        return moved
    else
        print("Unknown query mode: " .. mode)
        print("Valid modes: count, high, low, bal")
        return nil
    end
end

-- CLI entry point
local function main(args)
    -- Parse flags
    local verbose = false
    local debug = false
    local filteredArgs = {}
    for _, arg in ipairs(args) do
        if arg == "-v" or arg == "--verbose" then
            verbose = true
        elseif arg == "-d" or arg == "--debug" then
            debug = true
        else
            table.insert(filteredArgs, arg)
        end
    end

    -- Enable debug mode if requested
    if debug then
        imv.setDebug(true)
    end

    -- Check for query command
    if #filteredArgs >= 1 then
        local item, mode, param = parseQuery(filteredArgs[1])
        if item then
            handleQuery(item, mode, verbose, param)
            return
        end
    end

    if #filteredArgs < 2 then
        print("Usage: imv [-v] [-d] <source> <destination>")
        print("       imv [-v] [-d] q:<item>:<mode>[:<limit>]")
        print("")
        print("MOVE PATTERN: <location>/<item>:<count>")
        print("  -v: verbose output")
        print("  -d: debug mode (verbose + crash on error)")
        print("  location: peripheral name, fuzzy match (chest23), ./ (self), * or ../ (any)")
        print("  item: item name or fuzzy match, optional (defaults to *)")
        print("  count: number, * or + for one stack, ++ for ALL (defaults to 1)")
        print("")
        print("Move examples:")
        print("  imv chest23/lava:1 ./        -- 1 lava from chest23 to self")
        print("  imv ./coal:* chest23         -- full stack of coal from self to chest23")
        print("  imv */diamond:+ ./           -- full stack of diamonds from anywhere to self")
        print("  imv ./lava:1 ../             -- 1 lava from self to any available chest")
        print("  imv ./*:++ ../               -- ALL items from self to network")
        print("")
        print("QUERY PATTERN: q:<item>:<mode>[:<limit>]")
        print("  count: total items matching pattern across network")
        print("  high:  inventory with most of the item")
        print("  low:   inventory with least of the item (>0)")
        print("  bal:   distribute evenly across all chests (total/numChests)")
        print("  limit: (bal only) keep looping until moved < limit")
        print("")
        print("Query examples:")
        print("  imv q:diamond:count          -- total diamonds on network")
        print("  imv q:coal:high              -- chest with most coal")
        print("  imv q:iron:low               -- chest with least iron")
        print("  imv -v q:gold:bal            -- distribute gold evenly")
        print("  imv -v q:coal:bal:10         -- keep balancing until <10 moved")
        print("")
        print("Use as library: local imv = require('imv')")
        return
    end

    local count, err = imv.move(filteredArgs[1], filteredArgs[2], {verbose = verbose})
    if err then
        print("Error: " .. err)
        return false
    end
    return true
end

-- Check if running as CLI or being required as library
-- When required, ... contains the module name (e.g., "imv" or "/bin/imv")
-- When run as CLI, ... contains command line arguments
local args = {...}
local firstArg = args[1]

-- Detect if this looks like a require() call (module path passed)
local isRequire = type(firstArg) == "string" and
                  (firstArg == "imv" or
                   firstArg:match("^/") or           -- absolute path like /bin/imv
                   firstArg:match("^[%w_]+$"))       -- simple module name

-- Run as CLI if not a require and has valid CLI args
local isCLI = not isRequire and
              (#args == 0 or
               (type(firstArg) == "string" and
                (firstArg:match("^%-") or      -- starts with flag
                 firstArg:match("^q:") or      -- query pattern
                 firstArg:match("^%./") or     -- ./ path
                 firstArg:match("^%.%./") or   -- ../ path
                 firstArg:match("^%*") or      -- * wildcard
                 #args >= 2)))                 -- multiple args

if isCLI then
    local success = main(args)
    if success == false then
        return false  -- Signal failure to shell.run
    end
end

return imv
