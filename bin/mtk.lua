-- mtk.lua

local move, itemTypes, lib_debug

-- Try to load libraries, use basic functionality if not available
local success, result = pcall(require, "/lib/move")
if success then
    move = result
else
    move = nil
end

success, result = pcall(require, "/lib/item_types")
if success then
    itemTypes = result
else
    itemTypes = {}
end

success, result = pcall(require, "/lib/lib_debug")
if success then
    lib_debug = result
end

local mtk = {}

-- User-defined variables
mtk.waypoint = {}
mtk.chest = {}
mtk.func = {}
mtk.debug = false
mtk.quit_flag = false
mtk.inventory_snapshot = {}
mtk.lastSelected = 1

-- New variables for jump and function call-like behavior
mtk.jump_counts = {}
mtk.jump_stacks = {}
mtk.current_index = 1

-- Debug function
local function debug_print(...)
    if lib_debug then
        lib_debug.print_debug(...)
    elseif mtk.debug then
        print("[DEBUG]", ...)
    end
end

-- Helper functions
local function goTo(x, z, depth)
    if move and move.pathTo then
        move.pathTo(x, z, depth, true)
    else
        print("Advanced navigation not available. Please move manually.")
    end
end

local function getPos()
    if move and move.getPos then
        return move.getPos()
    else
        return 0, 0, 0  -- Default position if not available
    end
end

-- Inventory management functions
local function take_inventory_snapshot()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        mtk.inventory_snapshot[i] = item and item.name or nil
    end
end

local function find_item_in_inventory(item_name)
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == item_name and turtle.getItemCount(i) > 1 then
            return i
        end
    end
    return nil
end

local function replenish_slot(slot)
    local target_item = mtk.inventory_snapshot[slot]
    if not target_item then return false end

    local source_slot = find_item_in_inventory(target_item)
    if not source_slot then return false end

    local current_slot = turtle.getSelectedSlot()
    turtle.select(source_slot)
    local success = turtle.transferTo(slot, turtle.getItemCount(source_slot) - 1)
    turtle.select(current_slot)
    return success
end

-- Serialization functions
local function serialize_snapshot(path)
    local file = io.open(path, "w")
    if not file then
        print("Error: Unable to open file for writing")
        return false
    end
    for i, item in ipairs(mtk.inventory_snapshot) do
        file:write(i .. "," .. (item or "nil") .. "\n")
    end
    file:close()
    return true
end

local function deserialize_snapshot(path)
    local file = io.open(path, "r")
    if not file then
        print("Error: Unable to open file for reading")
        return false
    end
    mtk.inventory_snapshot = {}
    for line in file:lines() do
        local index, item = line:match("(%d+),(.+)")
        index = tonumber(index)
        if item == "nil" then item = nil end
        mtk.inventory_snapshot[index] = item
    end
    file:close()
    return true
end

-- Macro functions
local macro_functions = {
    mf = function() 
        debug_print("Move forward") 
        if move then 
            return move.goForward(true)
        else 
            return turtle.forward()
        end 
    end,
    mb = function() 
        debug_print("Move back") 
        if move then 
            return move.goBackwards(true)
        else 
            return turtle.back()
        end 
    end,
    mu = function() 
        debug_print("Move up") 
        if move then 
            return move.goUp(true)
        else 
            return turtle.up()
        end 
    end,
    md = function() 
        debug_print("Move down") 
        if move then 
            return move.goDown(true)
        else 
            return turtle.down()
        end 
    end,
    tr = function() 
        debug_print("Turn right") 
        if move then 
            move.turnRight()
        else 
            turtle.turnRight()
        end 
        return true
    end,
    tl = function() 
        debug_print("Turn left") 
        if move then 
            move.turnLeft()
        else 
            turtle.turnLeft()
        end 
        return true
    end,
    df = function() debug_print("Dig forward") turtle.dig() end,
    du = function() debug_print("Dig up") turtle.digUp() end,
    dd = function() debug_print("Dig down") turtle.digDown() end,
    s = function(c)
        local slot = tonumber(c, 16) + 1  -- Convert hex to decimal and add 1
        if slot and slot >= 1 and slot <= 16 then
            debug_print("Select slot", slot)
            if turtle.getItemCount(slot) <= 1 and mtk.inventory_snapshot[slot] then
                if not replenish_slot(slot) then
                    return false, "Failed to replenish slot " .. c
                end
            end
            turtle.select(slot)
            mtk.lastSelected = slot
        else
            debug_print("Invalid slot:", c)
            return false, "Invalid slot: " .. c
        end
        return true
    end,
    S = function(c)
        local slot = tonumber(c, 16) + 1  -- Convert hex to decimal and add 1
        if slot and slot >= 1 and slot <= 16 then
            debug_print("Blindly select slot", slot)
            turtle.select(slot)
            mtk.lastSelected = slot
        else
            debug_print("Invalid slot:", c)
        end
        return true
    end,
    pf = function() 
        debug_print("Place forward") 
        local current_slot = turtle.getSelectedSlot()
        if turtle.getItemCount(current_slot) <= 1 then
            if not replenish_slot(current_slot) then
                return false, "Failed to replenish items for placing"
            end
        end
        return turtle.place()
    end,
    pu = function() 
        debug_print("Place up") 
        local current_slot = turtle.getSelectedSlot()
        if turtle.getItemCount(current_slot) <= 1 then
            if not replenish_slot(current_slot) then
                return false, "Failed to replenish items for placing"
            end
        end
        return turtle.placeUp()
    end,
    pd = function() 
        debug_print("Place down") 
        local current_slot = turtle.getSelectedSlot()
        if turtle.getItemCount(current_slot) <= 1 then
            if not replenish_slot(current_slot) then
                return false, "Failed to replenish items for placing"
            end
        end
        return turtle.placeDown()
    end,
    Pf = function() 
        debug_print("Blindly place forward") 
        if not turtle.place() then
            return false, "No items to place"
        end
        return true
    end,
    Pu = function() 
        debug_print("Blindly place up") 
        if not turtle.placeUp() then
            return false, "No items to place"
        end
        return true
    end,
    Pd = function() 
        debug_print("Blindly place down") 
        if not turtle.placeDown() then
            return false, "No items to place"
        end
        return true
    end,
    lf = function() 
        debug_print("Look forward")
        local success, data = turtle.inspect()
        if success then
            print("Forward:", data.name)
        else
            print("Forward: No block")
        end
    end,
    lu = function()
        debug_print("Look up")
        local success, data = turtle.inspectUp()
        if success then
            print("Up:", data.name)
        else
            print("Up: No block")
        end
    end,
    ld = function()
        debug_print("Look down")
        local success, data = turtle.inspectDown()
        if success then
            print("Down:", data.name)
        else
            print("Down: No block")
        end
    end,
    W = function(c)
        debug_print("Set waypoint", c)
        local x, z, depth = getPos()
        mtk.waypoint[c] = {x, z, depth}
        print("Waypoint " .. c .. " set to " .. x .. "," .. z .. "," .. depth)
    end,
    w = function(c)
        debug_print("Go to waypoint", c)
        if mtk.waypoint[c] then
            local x, z, depth = table.unpack(mtk.waypoint[c])
            goTo(x, z, depth)
        else
            print("Waypoint " .. c .. " not set")
        end
    end,
    C = function(c)
        debug_print("Set chest position", c)
        local x, z, depth = getPos()
        mtk.chest[c] = {x, z, depth - 1}  -- Set position below the turtle
        print("Chest " .. c .. " set to " .. x .. "," .. z .. "," .. (depth - 1))
    end,
    c = function(c)
        debug_print("Go to chest", c)
        if mtk.chest[c] then
            local x, z, depth = table.unpack(mtk.chest[c])
            goTo(x, z, depth)
        else
            print("Chest " .. c .. " not set")
        end
    end,
    f = function(c)
        debug_print("Run function", c)
        if mtk.func[c] then
            mtk.func[c]()
        else
            debug_print("No function defined for f" .. c)
        end
    end,
    re = function() 
        debug_print("Refuel") 
        if move and move.refuel then 
            move.refuel() 
        else 
            local success = false
            for i = 1, 16 do
                if turtle.getItemCount(i) > 0 then
                    turtle.select(i)
                    if turtle.refuel(1) then
                        success = true
                        break
                    end
                end
            end
            if not success then
                print("No fuel found")
            end
        end 
    end,
    dt = function() 
        debug_print("Dump Trash") 
        if move and move.dumpTrash then 
            move.dumpTrash() 
        else 
            print("Dump trash function not available")
        end 
    end,
    gh = function() 
        debug_print("Go Home") 
        if move and move.goHome then 
            move.goHome() 
        else 
            print("Go home function not available")
        end 
    end,
    Gh = function() 
        debug_print("Set Home") 
        if move and move.setHome then 
            move.setHome() 
        else 
            print("Set home function not available")
        end 
    end,
    q = function()
        debug_print("Quit")
        mtk.quit_flag = true
    end,
    
    -- Deprecated functions
    x = function(c)
        debug_print("DEPRECATED: Loop start", c)
        print("Warning: 'x' is deprecated. Use 'J' and 'j' instead.")
        -- Functionality removed
    end,
    X = function(c)
        debug_print("DEPRECATED: Loop end", c)
        print("Warning: 'X' is deprecated. Use 'J' and 'j' instead.")
        -- Functionality removed
    end,
    
    -- New functions
    J = function(c)
        debug_print("Label", c)
        -- This is a no-op, just for labeling
        return true
    end,
    j = function(c)
        debug_print("Jump", c)
        local jump_count = mtk.jump_counts[c]
        if jump_count == nil then
            -- Function call-like behavior
            if not mtk.jump_stacks[c] then
                mtk.jump_stacks[c] = {}
            end
            if #mtk.jump_stacks[c] >= 1000 then
                return false, "Stack overflow for jump " .. c
            end
            table.insert(mtk.jump_stacks[c], mtk.current_index)
        elseif jump_count > 0 then
            mtk.jump_counts[c] = jump_count - 1
        end
        -- Find the corresponding label
        for i = 1, #mtk.macro_string, 2 do
            local func_code = mtk.macro_string:sub(i, i+1)
            if func_code == "J" .. c then
                mtk.current_index = i - 2  -- Set to just before the label
                return true
            end
        end
        return false, "Label J" .. c .. " not found"
    end,
    r = function(c)
        debug_print("Return", c)
        if mtk.jump_counts[c] ~= nil then
            return false, "Return called for non-function jump " .. c
        end
        if not mtk.jump_stacks[c] or #mtk.jump_stacks[c] == 0 then
            return false, "Return stack empty for jump " .. c
        end
        mtk.current_index = table.remove(mtk.jump_stacks[c])
        return true
    end
}

-- Main function to execute the macro
function mtk.execute_macro(macro_string, jump_counts)
    mtk.macro_string = macro_string
    mtk.jump_counts = jump_counts or {}
    mtk.jump_stacks = {}
    mtk.current_index = 1
    mtk.quit_flag = false
    take_inventory_snapshot()

    while mtk.current_index <= #macro_string do
        local func_code = macro_string:sub(mtk.current_index, mtk.current_index + 1)
        local main_code = func_code:sub(1, 1)
        local sub_code = func_code:sub(2, 2)

        local result, error_message
        if macro_functions[func_code] then
            result, error_message = macro_functions[func_code]()
        elseif macro_functions[main_code] then
            result, error_message = macro_functions[main_code](sub_code)
        else
            print("Unknown macro command: " .. func_code)
            return false, "Unknown command"
        end

        if result == false and error_message then
            local message = string.format("Error at index %d: %s", mtk.current_index, error_message)
            print(message)
            return false, message
        end

        if mtk.quit_flag then
            return true
        end

        mtk.current_index = mtk.current_index + 2
    end
    return true
end

-- Command-line interface
local function print_usage()
    print("Usage: mtk [-m <macro_string>] [-j <jump_counts>] [-x <loop_counts>] [-v] [-t] [-S <save_path>] [-s <load_path>]")
    print("  -m, --macro    Macro string (required unless -t is used)")
    print("  -j, --jumps    Jump counts, format: <n1>,<n2>,<n3>... (optional)")
    print("  -x             DEPRECATED: Loop counts (use -j instead)")
    print("  -v, --verbose  Enable debug output")
    print("  -t, --test     Enter test interface (REPL mode)")
    print("  -S <path>      Serialize and save inventory snapshot to file")
    print("  -s <path>      Load inventory snapshot from file")
    print("  -h, --help     Print this help message")
end

-- Clear console function
local function clear_console()
    if term then
        term.clear()
        term.setCursorPos(1, 1)
    else
        for i = 1, 50 do print() end  -- Fallback if term API is not available
    end
end

-- Test interface (REPL)
local function run_test_interface()
    print("Entering test interface. Type 'exit' or 'q' to quit, 'clear' to clear console.")
    take_inventory_snapshot()  -- Take initial inventory snapshot

    while true do
        io.write("m> ")
        local input = io.read()
        if input == "exit" or input == "q" then
            break
        elseif input == "clear" then
            clear_console()
        else
            local jump_counts = {}
            local success, error_message = mtk.execute_macro(input, jump_counts)
            if not success and error_message then
                print(error_message)
            elseif mtk.quit_flag then
                break
            end
        end
    end
end

function mtk.run_cli(args)
    local macro_string = nil
    local jump_counts = {}
    local test_mode = false
    local save_path = nil
    local load_path = nil
    local deprecated_x_used = false

    local i = 1
    while i <= #args do
        if args[i] == "-h" or args[i] == "--help" then
            print_usage()
            return
        elseif args[i] == "-m" or args[i] == "--macro" then
            i = i + 1
            macro_string = args[i]
        elseif args[i] == "-j" or args[i] == "--jumps" then
            i = i + 1
            for count in args[i]:gmatch("([^,]+)") do
                table.insert(jump_counts, tonumber(count) or nil)
            end
        elseif args[i] == "-x" then
            deprecated_x_used = true
            i = i + 1
            for count in args[i]:gmatch("%S+") do
                table.insert(jump_counts, tonumber(count))
            end
        elseif args[i] == "-v" or args[i] == "--verbose" then
            mtk.debug = true
            if lib_debug then
                lib_debug.set_verbose(true)
            end
        elseif args[i] == "-t" or args[i] == "--test" then
            test_mode = true
        elseif args[i] == "-S" then
            i = i + 1
            save_path = args[i]
        elseif args[i] == "-s" then
            i = i + 1
            load_path = args[i]
        else
            print("Unknown argument: " .. args[i])
            print_usage()
            return
        end
        i = i + 1
    end

    if deprecated_x_used then
        print("Warning: The -x argument is deprecated. Please use -j instead.")
        print("Example: -j " .. table.concat(jump_counts, ","))
    end

    if load_path then
        if not deserialize_snapshot(load_path) then
            print("Failed to load inventory snapshot from " .. load_path)
            return
        end
    else
        take_inventory_snapshot()
    end

    if save_path then
        if not serialize_snapshot(save_path) then
            print("Failed to save inventory snapshot to " .. save_path)
            return
        end
    end

    if test_mode then
        run_test_interface()
    elseif not macro_string then
        print("Error: Macro string is required unless in test mode")
        print_usage()
        return
    else
        mtk.execute_macro(macro_string, jump_counts)
    end
end

-- Check if this script is being run directly
if arg then
    mtk.run_cli(arg)
end

-- Module interface
return setmetatable(mtk, {
    __call = function(_, macro_string, jump_counts)
        return mtk.execute_macro(macro_string, jump_counts)
    end
})