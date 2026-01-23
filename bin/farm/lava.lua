--[[
lava.lua - Lava farming from cauldrons with snake traversal

The turtle starts facing a wired modem. It empties inventory, grabs empty buckets,
moves to the starting position (tlmftlmfmf), sets home, then farms lava from
cauldrons above in a snake pattern until it runs out of empty buckets or hits
a dead end.

The turtle alternates turn direction at each row end (left, right, left, right...)
]]

local imv = require("/bin/imv")
local move = require("/lib/move")
local mtk = require("/bin/mtk")

local SLEEP_TIME = 300 -- 5 minutes in seconds

-- Find and select a slot containing an empty bucket
-- Returns true if found, false otherwise
local function selectEmptyBucket()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:bucket" then
            turtle.select(slot)
            return true
        end
    end
    return false
end

-- Count empty buckets in inventory
local function countEmptyBuckets()
    local count = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:bucket" then
            count = count + item.count
        end
    end
    return count
end

-- Check if there's a cauldron with lava above
local function isLavaCauldronAbove()
    local success, data = turtle.inspectUp()
    if success and data.name and data.name:find("lava_cauldron") then
        return true
    end
    return false
end

-- Try to fill bucket with lava from cauldron above
-- Returns true if successfully filled
local function tryFillBucket()
    if not isLavaCauldronAbove() then
        return false
    end

    if selectEmptyBucket() then
        if turtle.placeUp() then
            print("Filled bucket with lava")
            return true
        end
    end
    return false
end

-- Check if forward is empty (no block)
local function isForwardEmpty()
    return not turtle.detect()
end

-- Empty all inventory to network
local function emptyInventory()
    print("Emptying inventory to network...")
    local totalDumped = 0
    while true do
        local count, err = imv.move("./*:++", "../")
        if count > 0 then
            totalDumped = totalDumped + count
        else
            break
        end
    end
    if totalDumped > 0 then
        print("Dumped " .. totalDumped .. " item(s)")
    end
    return totalDumped
end

-- Refuel with lava buckets if fuel is low
local function refuelIfNeeded()
    local fuelLevel = turtle.getFuelLevel()

    if fuelLevel == "unlimited" then
        return
    end

    if fuelLevel >= 1000 then
        return
    end

    print("Fuel low (" .. fuelLevel .. "), refueling...")
    local refueled = 0
    while turtle.getFuelLevel() < 1000 do
        local found = false
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and item.name == "minecraft:lava_bucket" then
                turtle.select(slot)
                if turtle.refuel() then
                    refueled = refueled + 1
                    found = true
                    break
                end
            end
        end
        if not found then
            break
        end
    end

    if refueled > 0 then
        print("Used " .. refueled .. " lava bucket(s) for fuel (now: " .. turtle.getFuelLevel() .. ")")
    end
end

-- Deposit all lava buckets to network
local function depositLavaBuckets()
    print("Depositing lava buckets to network...")
    local totalDeposited = 0
    while true do
        local count, err = imv.move("./lava_bucket:++", "../")
        if count > 0 then
            totalDeposited = totalDeposited + count
        else
            break
        end
    end
    if totalDeposited > 0 then
        print("Deposited " .. totalDeposited .. " lava bucket(s)")
    end
    return totalDeposited
end

-- Get empty buckets from network, retry until we have some
local function getEmptyBuckets()
    while true do
        print("Getting empty buckets from network...")
        local count, err = imv.move("../=bucket:16", "./")
        if count > 0 then
            print("Got " .. count .. " empty bucket(s)")
            return count
        else
            print("No empty buckets available, waiting 5 minutes...")
            sleep(SLEEP_TIME)
        end
    end
end

-- Main farming function
local function farmLava()
    print("Starting lava farm")
    print("Facing wired modem, ready to begin")

    while true do
        print("\n=== Starting farming cycle ===")

        -- Step 1: Empty inventory
        emptyInventory()

        -- Step 2: Get 16 empty buckets (waits if none available)
        getEmptyBuckets()

        -- Step 3: Go to starting position (tlmftlmfmf)
        print("Moving to starting position...")
        mtk("tlmftlmfmf")

        -- Step 4: Set as home
        move.setHome()
        print("Home position set")

        -- Step 5: Start farming
        local direction = "left" -- alternates between left and right

        while true do
            -- Try to fill bucket from cauldron above
            tryFillBucket()

            -- Check if we have any empty buckets left
            if countEmptyBuckets() == 0 then
                print("No more empty buckets, returning home")
                move.goHome()
                break
            end

            -- Try to move forward
            if isForwardEmpty() then
                move.goForward(false)
            else
                -- Can't go forward, try to turn to next row
                local turnSuccess = false

                if direction == "left" then
                    move.turnLeft()
                    if isForwardEmpty() then
                        move.goForward(false)
                        move.turnLeft()
                        turnSuccess = true
                    else
                        move.turnRight() -- undo turn
                    end
                else
                    move.turnRight()
                    if isForwardEmpty() then
                        move.goForward(false)
                        move.turnRight()
                        turnSuccess = true
                    else
                        move.turnLeft() -- undo turn
                    end
                end

                if turnSuccess then
                    -- Flip direction for next row
                    if direction == "left" then
                        direction = "right"
                    else
                        direction = "left"
                    end
                else
                    -- Dead end, return home
                    print("Dead end reached, returning home")
                    move.goHome()
                    break
                end
            end
        end

        -- Back at home (modem position after going through tlmftlmfmf path)
        -- Need to reverse the path to get back to modem
        print("Returning to modem position...")
        mtk("trtrmfmftrmftl") -- reverse of tlmftlmfmf

        -- Refuel if needed before depositing lava
        refuelIfNeeded()

        -- Deposit remaining lava buckets to network
        depositLavaBuckets()

        -- Cycle complete, loop back to start
        print("Cycle complete")
    end
end

-- Run the farm
farmLava()
