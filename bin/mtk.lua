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
        if item and item.name == item_name then
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

    turtle.select(source_slot)
    turtle.transferTo(slot)
    return true
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
                    return false, mtk.inventory_snapshot[slot]
                end
            end
            turtle.select(slot)
            mtk.lastSelected = slot
        else
            debug_print("Invalid slot:", c)
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
        if turtle.getItemCount(turtle.getSelectedSlot()) <= 1 then
            if not replenish_slot(mtk.lastSelected) then
                return false, mtk.inventory_snapshot[mtk.lastSelected]
            end
        end
        return turtle.place()
    end,
    pu = function() 
        debug_print("Place up") 
        if turtle.getItemCount(turtle.getSelectedSlot()) <= 1 then
            if not replenish_slot(mtk.lastSelected) then
                return false, mtk.inventory_snapshot[mtk.lastSelected]
            end
        end
        return turtle.placeUp()
    end,
    pd = function() 
        debug_print("Place down") 
        if turtle.getItemCount(turtle.getSelectedSlot()) <= 1 then
            if not replenish_slot(mtk.lastSelected) then
                return false, mtk.inventory_snapshot[mtk.lastSelected]
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
        if mtk.func[c] then
            debug_print("Run function", c)
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
    end
}

-- Main function to execute the macro
function mtk.execute_macro(macro_string, loop_count, start_index)
    loop_count = loop_count or 1
    start_index = start_index or 1
    mtk.quit_flag = false
    take_inventory_snapshot()
    
    for current_loop = 1, loop_count do
        for i = start_index, #macro_string, 2 do
            local func_code = macro_string:sub(i, i+1)
            local main_code = func_code:sub(1, 1)
            local sub_code = func_code:sub(2, 2)
            
            local result, error_message
            if macro_functions[func_code] then
                result, error_message = macro_functions[func_code]()
            elseif macro_functions[main_code] then
                if main_code == "s" or main_code == "S" or main_code == "W" or main_code == "w" or main_code == "C" or main_code == "c" or main_code == "f" then
                    result, error_message = macro_functions[main_code](sub_code)
                else
                    result, error_message = macro_functions[main_code]()
                end
            else
                print("Unknown macro command: " .. func_code)
                return false, "Unknown command"
            end
            
            if result == false and error_message then
                local message = string.format("Paused at index %d, loop %d. Error: %s", i, current_loop, error_message)
                print(message)
                return false, message
            end
            
            if mtk.quit_flag then
                return true
            end
        end
        start_index = 1  -- Reset start_index after the first loop
    end
    return true
end

-- Command-line interface
local function print_usage()
    print("Usage: mtk [-m <macro_string>] [-l <loop_count>] [-i <start_index>] [-v] [-t] [-S <save_path>] [-s <load_path>]")
    print("  -m, --macro    Macro string (required unless -t is used)")
    print("  -l, --loop     Number of times to loop the macro (optional, default: 1)")
    print("  -i, --index    Starting index for the macro (optional, default: 1)")
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
    local command_index = 0
    
    while true do
        io.write("m> ")
        local input = io.read()
        if input == "exit" or input == "q" then
            break
        elseif input == "clear" then
            clear_console()
        else
            command_index = command_index + 1
            local success, error_message = mtk.execute_macro(input)
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
    local loop_count = 1
    local start_index = 1
    local test_mode = false
    local save_path = nil
    local load_path = nil

    local i = 1
    while i <= #args do
        if args[i] == "-h" or args[i] == "--help" then
            print_usage()
            return
        elseif args[i] == "-m" or args[i] == "--macro" then
            i = i + 1
            macro_string = args[i]
        elseif args[i] == "-l" or args[i] == "--loop" then
            i = i + 1
            loop_count = tonumber(args[i])
        elseif args[i] == "-i" or args[i] == "--index" then
            i = i + 1
            start_index = tonumber(args[i])
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
        mtk.execute_macro(macro_string, loop_count, start_index)
    end
end

-- Check if this script is being run directly
if arg then
    mtk.run_cli(arg)
end

-- Module interface
return setmetatable(mtk, {
    __call = function(_, macro_string, loop_count, start_index)
        return mtk.execute_macro(macro_string, loop_count, start_index)
    end
})