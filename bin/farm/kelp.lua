--[[
kelp.lua - Kelp farming script

The turtle starts facing a wired modem. It moves up one block, turns around,
then farms kelp in a zigzag pattern by harvesting plants in front and below.
When done, it returns home, moves down to the modem, and dumps/refuels.

Kelp regrows naturally from the base, so no replanting is needed.
]]

local imv = require("/bin/imv")
local move = require("/lib/move")

-- Check fuel and refuel from network if needed
local function checkAndRefuel()
    local fuelLevel = turtle.getFuelLevel()

    if fuelLevel == "unlimited" then
        return true
    end

    if fuelLevel >= 1000 then
        return true
    end

    print("Fuel low (" .. fuelLevel .. "), getting lava bucket...")
    local count, err = imv.move("../lava_bucket:1", "./")
    if count > 0 then
        -- Find and use the lava bucket
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and item.name == "minecraft:lava_bucket" then
                turtle.select(slot)
                if turtle.refuel() then
                    print("Refueled to " .. turtle.getFuelLevel())
                    -- Return empty bucket to network
                    local returned, retErr = imv.move("./=bucket:1", "../")
                    if returned > 0 then
                        print("Returned empty bucket to network")
                    end
                    return true
                end
            end
        end
    else
        print("Could not get lava bucket: " .. (err or "none available"))
    end

    return turtle.getFuelLevel() >= 1000
end

-- Check if block is kelp
local function isKelp(data)
    return data and (data.name == "minecraft:kelp" or data.name == "minecraft:kelp_plant")
end

-- Check and harvest kelp below if present
local function checkAndHarvestBelow()
    local success, data = turtle.inspectDown()
    if success and isKelp(data) then
        turtle.digDown()
        return true
    end
    return false
end

-- Check and harvest kelp in front if present
local function checkAndHarvestFront()
    local success, data = turtle.inspect()
    if not success then
        -- Nothing in front (water or air)
        return false
    end

    if isKelp(data) then
        turtle.dig()
        return true
    end

    -- Something in front but not kelp (wall, etc) - that's fine
    return false
end

-- Try to move forward, dig if blocked by something diggable
local function tryMoveForward()
    -- First try without digging
    if move.goForward(false) then
        return true
    end

    -- If blocked, check what's in front
    local success, data = turtle.inspect()
    if success then
        -- Something solid in front - try to dig it (could be kelp stem, etc)
        if data.name == "minecraft:kelp" or data.name == "minecraft:kelp_plant" then
            turtle.dig()
            return move.goForward(false)
        end
        -- Hit an actual wall/boundary - don't dig
        return false
    end

    -- Nothing detected but can't move (shouldn't happen underwater)
    -- Try one more time
    return move.goForward(false)
end

-- Dump harvested kelp to network
local function dumpToNetwork()
    print("Dumping harvested kelp to network...")
    local totalDumped = 0

    local dumpItems = {
        "kelp"
    }

    for _, item in ipairs(dumpItems) do
        while true do
            local count, err = imv.move("./" .. item .. ":*", "../")
            if count > 0 then
                totalDumped = totalDumped + count
            else
                break
            end
        end
    end

    if totalDumped > 0 then
        print("Dumped " .. totalDumped .. " item(s)")
    end
end

-- Main farming function
local function farmKelp()
    print("Starting kelp farm")
    print("Facing wired modem, ready to begin")

    while true do
        print("\n=== Starting farming cycle ===")

        -- Check and refuel if needed
        if not checkAndRefuel() then
            print("Warning: Low fuel, continuing anyway...")
        end

        -- Move up one block to farming level
        move.goUp()

        -- Reset position tracking (at farming level, not modem level)
        move.setHome()

        -- Turn around (face away from modem)
        move.turnRight()
        move.turnRight()

        -- Track which direction we turn at end of rows
        local turnRight = true

        -- Main farming loop
        while true do
            -- Check and harvest in front if kelp
            checkAndHarvestFront()

            -- Check and harvest below current position
            checkAndHarvestBelow()

            -- Try to move forward
            if not tryMoveForward() then
                -- Check what's blocking us
                local success, data = turtle.inspect()
                if success then
                    print("Blocked by: " .. data.name)
                else
                    print("Blocked but nothing detected")
                end

                -- Try to turn to next row
                local turnSuccess = false
                if turnRight then
                    move.turnRight()
                    -- Harvest any kelp blocking the next row
                    checkAndHarvestFront()
                    checkAndHarvestBelow()
                    if tryMoveForward() then
                        move.turnRight()
                        turnSuccess = true
                    else
                        -- Can't move to next row, end of farm
                        move.turnLeft() -- undo the turn
                    end
                else
                    move.turnLeft()
                    -- Harvest any kelp blocking the next row
                    checkAndHarvestFront()
                    checkAndHarvestBelow()
                    if tryMoveForward() then
                        move.turnLeft()
                        turnSuccess = true
                    else
                        -- Can't move to next row, end of farm
                        move.turnRight() -- undo the turn
                    end
                end

                if turnSuccess then
                    -- Successfully turned to next row, flip direction for next time
                    turnRight = not turnRight
                else
                    -- End of farm reached
                    print("End of farm reached")
                    break
                end
            end
        end

        -- Return to start position on horizontal plane (still one block above modem)
        print("Returning to start...")
        move.goHome()

        -- Move down to modem level
        move.goDown()

        -- goHome() already returned us facing the original direction (toward modem)
        -- No need to turn - we should be facing the modem now

        -- Dump harvested kelp to network
        dumpToNetwork()

        -- Pause before next cycle
        print("Cycle complete, sleeping for 5 minutes...")
        sleep(300)
    end
end

-- Run the farm
farmKelp()
