-- mtk_unit_test.lua

local mtk = require("/bin/mtk")

-- Backup original turtle
local original_turtle = _G.turtle

-- Variable to track turtle actions
local turtle_test_path = ""

-- Helper function to append action to turtle_test_path
local function record_action(action)
    turtle_test_path = turtle_test_path .. action
end

-- Mock turtle functions
local mock_turtle = {
    forward = function() record_action("mf") return true end,
    back = function() record_action("mb") return true end,
    up = function() record_action("mu") return true end,
    down = function() record_action("md") return true end,
    turnLeft = function() record_action("tl") return true end,
    turnRight = function() record_action("tr") return true end,
    dig = function() record_action("df") return true end,
    digUp = function() record_action("du") return true end,
    digDown = function() record_action("dd") return true end,
    place = function() record_action("pf") return true end,
    placeUp = function() record_action("pu") return true end,
    placeDown = function() record_action("pd") return true end,
    detect = function() record_action("df") return false end,
    detectUp = function() record_action("du") return false end,
    detectDown = function() record_action("dd") return false end,
    inspect = function() record_action("lf") return true, {name = "minecraft:stone"} end,
    inspectUp = function() record_action("lu") return true, {name = "minecraft:dirt"} end,
    inspectDown = function() record_action("ld") return true, {name = "minecraft:grass_block"} end,
    select = function(slot) 
        local hex_slot = string.format("%x", slot - 1)
        record_action("s" .. hex_slot) 
        mock_turtle.selected_slot = slot 
        return true 
    end,
    getItemCount = function() record_action("") return 64 end,
    getItemDetail = function() record_action("") return {name = "minecraft:cobblestone", count = 64} end,
    getFuelLevel = function() record_action("") return 1000 end,
    refuel = function() record_action("re") return true end,
    selected_slot = 1
}

-- Function to set up failure scenarios
local function set_failure_scenario(scenario)
    if scenario == "bedrock" then
        mock_turtle.dig = function() record_action("df") return false end
        mock_turtle.digUp = function() record_action("du") return false end
        mock_turtle.digDown = function() record_action("dd") return false end
    elseif scenario == "blocked_movement" then
        mock_turtle.forward = function() record_action("mf") return false end
        mock_turtle.up = function() record_action("mu") return false end
        mock_turtle.down = function() record_action("md") return false end
    elseif scenario == "place_blocked" then
        mock_turtle.place = function() record_action("pf") return false end
        mock_turtle.placeUp = function() record_action("pu") return false end
        mock_turtle.placeDown = function() record_action("pd") return false end
    else
        -- Reset to default behavior
        mock_turtle.dig = function() record_action("df") return true end
        mock_turtle.digUp = function() record_action("du") return true end
        mock_turtle.digDown = function() record_action("dd") return true end
        mock_turtle.forward = function() record_action("mf") return true end
        mock_turtle.up = function() record_action("mu") return true end
        mock_turtle.down = function() record_action("md") return true end
        mock_turtle.place = function() record_action("pf") return true end
        mock_turtle.placeUp = function() record_action("pu") return true end
        mock_turtle.placeDown = function() record_action("pd") return true end
    end
end

-- Replace global turtle with mock
_G.turtle = mock_turtle

-- Test helper functions
local function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(message .. " (Expected: " .. tostring(expected) .. ", Got: " .. tostring(actual) .. ")", 2)
    end
end

local function assert_path(expected, message)
    assert_equal(expected, turtle_test_path, message .. " - Incorrect action sequence")
end

local function clear_path()
    turtle_test_path = ""
end

-- Test cases
local tests = {
    -- ... [Previous test cases remain unchanged] ...

    test_dig_bedrock = function()
        clear_path()
        set_failure_scenario("bedrock")
        local success, _ = pcall(function() mtk("dfdudd") end)
        assert_path("dfdudd", "Dig bedrock test failed")
        assert_equal(false, success, "Dig bedrock should have failed")
        set_failure_scenario(nil)  -- Reset to default behavior
    end,

    test_blocked_movement = function()
        clear_path()
        set_failure_scenario("blocked_movement")
        local success, _ = pcall(function() mtk("mfmumd") end)
        assert_path("mfmumd", "Blocked movement test failed")
        assert_equal(false, success, "Blocked movement should have failed")
        set_failure_scenario(nil)  -- Reset to default behavior
    end,

    test_place_blocked = function()
        clear_path()
        set_failure_scenario("place_blocked")
        local success, _ = pcall(function() mtk("pfpupd") end)
        assert_path("pfpupd", "Place blocked test failed")
        assert_equal(false, success, "Place blocked should have failed")
        set_failure_scenario(nil)  -- Reset to default behavior
    end,

    test_combined_failure = function()
        clear_path()
        set_failure_scenario("bedrock")
        local success, _ = pcall(function() mtk("dfmfpf") end)
        assert_path("dfmfpf", "Combined failure test failed")
        assert_equal(false, success, "Combined failure should have failed")
        set_failure_scenario(nil)  -- Reset to default behavior
    end
}

-- Run tests
local function run_tests()
    local passed = 0
    local failed = 0

    for name, func in pairs(tests) do
        local success, error_message = pcall(func)
        if success then
            print("PASS: " .. name)
            passed = passed + 1
        else
            print("FAIL: " .. name .. " - " .. error_message)
            failed = failed + 1
        end
    end

    print("\nTest Results:")
    print("Passed: " .. passed)
    print("Failed: " .. failed)
    print("Total:  " .. (passed + failed))
end

-- Run the tests
run_tests()

-- Restore original turtle
_G.turtle = original_turtle

print("\nOriginal turtle object restored.")