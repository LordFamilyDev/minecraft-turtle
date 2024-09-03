-- mtk_unit_test.lua

--test to add to validate nested loop functioning with main loop:
--mtk -m mumux1mdX1 -x 2 -l 2  (should return to initial position if working correctly)

-- if _G.turtle is defined backup the original turtle object
if _G.turtle then
    _G.original_turtle = _G.turtle
end

-- if _G.term is nil define a mock term object
if not _G.term then
    _G.term = {
        setTextColor = function() end
    }
end

if not _G.colors then
    _G.colors = {
        white = 1,
        red = 2,
        green = 3
    }
end

-- Variable to track turtle actions
local turtle_test_path = ""

-- Helper function to append action to turtle_test_path
local function record_action(action)
    turtle_test_path = turtle_test_path .. action
end

-- Mock turtle functions
local mock_turtle = {
    -- Movement
    forward = function() record_action("mf") return true end,
    back = function() record_action("mb") return true end,
    up = function() record_action("mu") return true end,
    down = function() record_action("md") return true end,
    turnLeft = function() record_action("tl") return true end,
    turnRight = function() record_action("tr") return true end,
    -- Digging and placing
    dig = function() record_action("df") return true end,
    digUp = function() record_action("du") return true end,
    digDown = function() record_action("dd") return true end,
    place = function() record_action("pf") return true end,
    placeUp = function() record_action("pu") return true end,
    placeDown = function() record_action("pd") return true end,
    -- Looking
    inspect = function() record_action("lf") return true, {name = "minecraft:stone"} end,
    inspectUp = function() record_action("lu") return true, {name = "minecraft:dirt"} end,
    inspectDown = function() record_action("ld") return true, {name = "minecraft:grass_block"} end,
    -- Inventory
    select = function(slot) 
        local hex_slot = string.format("%x", slot - 1)
        record_action("s" .. hex_slot) 
        mock_turtle.selected_slot = slot 
        return true 
    end,
    -- Waypoints TODO
    -- Chest TODO
    -- Utility
    refuel = function() record_action("re") return true end,
    -- Required for mtk to load
    getItemDetail = function() return {name = "minecraft:stone"} end,
    detect = function() return true end,
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
local mtk = require("/bin/mtk")

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
    test_movement = function()
        clear_path()
        mtk("mfmbmumdtrtl")
        assert_path("mfmbmumdtrtl", "Movement test failed")
    end,
    -- test_movement_failure = function()
    --     clear_path()
    --     set_failure_scenario("blocked_movement")
    --     -- TODO - Add test for failure
    -- end,
    test_fake_movement = function()
        clear_path()
        mtk("mrml")
        assert_path("trmftltlmftr", "Fake Movement test failed")
    end,
    test_digging = function()
        clear_path()
        mtk("dfdudd")
        assert_path("dfdudd", "Digging test failed")
    end,
    -- test_digging_failure = function()
    --     clear_path()
    --     set_failure_scenario("bedrock")
    --     -- TODO - Add test for failure
    -- end,
    test_inspecting = function()
        clear_path()
        mtk("lfldlu")
        assert_path("lfldlu", "Inspecting test failed")
    end,
    test_loop = function()
        clear_path()
        mtk("mf", 2)
        assert_path("mfmf", "Loop test failed")
    end,
    test_jump = function()
        clear_path()
        mtk.loopMem = {}
        mtk.loopTargets = {2,3}
        mtk("x1mfX1")
        assert_path("mfmf", "Jump test failed")
    end,
    test_nested_jump = function()
        clear_path()
        mtk.loopMem = {}
        mtk.loopTargets = {2,3}
        mtk("x1mfx2trX2X1")
        assert_path("mftrtrtrmftrtrtr", "Nested loop test failed")
    end,
}

-- Run tests
local function run_tests()
    local passed = 0
    local failed = 0

    for name, func in pairs(tests) do
        local success, error_message = pcall(func)
        if success then
            term.setTextColor(colors.green) 
            print("PASS: " .. name)
            term.setTextColor(colors.white)
            passed = passed + 1
        else
            term.setTextColor(colors.red)
            print("FAIL: " .. name .. " - " .. error_message)
            term.setTextColor(colors.white)
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

-- Restore original turtle if it was backed up
if _G.original_turtle then
    _G.turtle = _G.original_turtle
end