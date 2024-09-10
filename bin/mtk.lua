-- mtk.lua

local move, itemTypes, lib_debug
local isLoaded_as_module = false

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

mtk.loopMem = {}
mtk.loopTargets = {}

-- Debug function
local function debug_print(...)
    if lib_debug then
        lib_debug.print_debug(...)
    elseif mtk.debug then
        print("[DEBUG]", ...)
    end
end

-- cli print function
local function cli_print(...)
    if isLoaded_as_module == false then
        print(...)
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
local macro_functions = {}

-- Move function
table.insert(macro_functions, {"m", function(c)
    debug_print("Move " .. c)
    local actions
    if move then
        actions = {
            f = move.goForward,
            b = move.goBackwards,
            u = move.goUp,
            d = move.goDown,
            l = function() return move.goLeft(false, true) end,
            r = function() return move.goRight(false, true) end,
            F = function() return move.goForward(true) end,
            B = function() return move.goBackwards(true) end,
            U = function() return move.goUp(true) end,
            D = function() return move.goDown(true) end,
            L = function() return move.goLeft(true, true) end,
            R = function() return move.goRight(true, true) end
        }
    else
        actions = {
            f = turtle.forward,
            b = turtle.back,
            u = turtle.up,
            d = turtle.down,
            l = function() return false end,
            r = function() return false end
        }
    end
    return actions[c] and actions[c](true) or false
end})

-- Turn function
table.insert(macro_functions, {"t", function(c)
    debug_print("Turn " .. c)
    local actions
    if move then
        actions = {
            r = move.turnRight,
            l = move.turnLeft
        }
    else
        actions = {
            r = turtle.turnRight,
            l = turtle.turnLeft
        }
    end
    return actions[c] and actions[c]() or false
end})

-- Dig function
table.insert(macro_functions, {"d", function(c)
    debug_print("Dig " .. c)
    local actions = {
        f = turtle.dig,
        u = turtle.digUp,
        d = turtle.digDown,
        F = turtle.dig,
        U = turtle.digUp,
        D = turtle.digDown
    }
    return actions[c] and actions[c]() or false
end})

-- Select function
table.insert(macro_functions, {"s", function(c)
    local slot = tonumber(c, 16) + 1
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
end})

-- Blindly Select function
table.insert(macro_functions, {"S", function(c)
    local slot = tonumber(c, 16) + 1
    if slot and slot >= 1 and slot <= 16 then
        debug_print("Blindly select slot", slot)
        turtle.select(slot)
        mtk.lastSelected = slot
    else
        debug_print("Invalid slot:", c)
    end
    return true
end})

-- Place function
table.insert(macro_functions, {"p", function(c)
    debug_print("Place:" .. c) 
    local current_slot = turtle.getSelectedSlot()
    if turtle.getItemCount(current_slot) <= 1 then
        if not replenish_slot(current_slot) then
            return false, "Failed to replenish items for placing"
        end
    end
    local actions = {
        f = turtle.place,
        u = turtle.placeUp,
        d = turtle.placeDown,
        F = function() while turtle.dig() do end return turtle.place() end,
        U = function() while turtle.digUp() do end return turtle.placeUp() end,
        D = function() while turtle.digDown() do end return turtle.placeDown() end
    }
    return actions[c] and actions[c]() or false
end})

-- Blindly Place function
table.insert(macro_functions, {"P", function(c)
    local actions = {
        f = turtle.place,
        u = turtle.placeUp,
        d = turtle.placeDown,
        F = function() while turtle.dig() do end return turtle.place() end,
        U = function() while turtle.digUp() do end return turtle.placeUp() end,
        D = function() while turtle.digDown() do end return turtle.placeDown() end
    }
    return actions[c] and actions[c]() or false
end})

-- Look function
table.insert(macro_functions, {"l", function(c)
    debug_print("Look " .. c)
    local actions = {
        f = turtle.inspect,
        u = turtle.inspectUp,
        d = turtle.inspectDown
    }
    if actions[c] then
        local success, data = actions[c]()
        if success then
            cli_print(c:upper() .. ":", data.name)
        else
            cli_print(c:upper() .. ": No block")
        end
    else
        cli_print("Invalid direction: " .. c)
        return false
    end
    return true
end})

-- Set Waypoint functions
table.insert(macro_functions, {"W", function(c)
    debug_print("Set waypoint", c)
    local x, z, depth = getPos()
    mtk.waypoint[c] = {x, z, depth}
    print("Waypoint " .. c .. " set to " .. x .. "," .. z .. "," .. depth)
end})

-- Go to Waypoint functions
table.insert(macro_functions, {"w", function(c)
    debug_print("Go to waypoint", c)
    if mtk.waypoint[c] then
        local x, z, depth = table.unpack(mtk.waypoint[c])
        goTo(x, z, depth)
    else
        print("Waypoint " .. c .. " not set")
    end
end})

-- Chest functions
table.insert(macro_functions, {"C", function(c)
    debug_print("Set chest position", c)
    local x, z, depth = getPos()
    mtk.chest[c] = {x, z, depth - 1}  -- Set position below the turtle
    print("Chest " .. c .. " set to " .. x .. "," .. z .. "," .. (depth - 1))
end})

table.insert(macro_functions, {"c", function(c)
    debug_print("Go to chest", c)
    if mtk.chest[c] then
        local x, z, depth = table.unpack(mtk.chest[c])
        goTo(x, z, depth)
    else
        print("Chest " .. c .. " not set")
    end
end})

-- Custom function
table.insert(macro_functions, {"f", function(c)
    if mtk.func[c] then
        debug_print("Run function", c)
        mtk.func[c]()
    else
        debug_print("No function defined for f" .. c)
    end
end})

-- Refuel function
table.insert(macro_functions, {"r", function(c)
    debug_print("Refuel")
    if move and move.refuel then
        return move.refuel()
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
        return success
    end
end})

-- Dump trash function
table.insert(macro_functions, {"d", function(c)
    debug_print("Dump Trash")
    if move and move.dumpTrash then
        return move.dumpTrash()
    else
        print("Dump trash function not available")
        return false
    end
end})

-- Go home function
table.insert(macro_functions, {"g", function(c)
    debug_print("Go Home")
    if move and move.goHome then
        return move.goHome()
    else
        print("Go home function not available")
        return false
    end
end})

-- Set home function
table.insert(macro_functions, {"G", function(c)
    debug_print("Set Home")
    if move and move.setHome then
        return move.setHome()
    else
        print("Set home function not available")
        return false
    end
end})

-- Placeholder function
table.insert(macro_functions, {"J", function(c)
    debug_print("Placeholder " .. c)
    -- This is a no-op function, it does nothing
    return true
end})

-- Initialize jump context
mtk.jump_context = {}

-- Jump function
table.insert(macro_functions, {"j", function(c, macro, current_index)
    local hex = tonumber(c, 16)
    if not hex or hex < 0 or hex > 15 then
        return false, "Invalid jump argument: " .. c
    end

    local j_pattern = string.format("j%s", c)
    local J_pattern = string.format("J%s", c)
    local r_pattern = string.format("r%s", c)

    local j_index = mtk.orig_macro:find(j_pattern, 1, true)
    local J_index = mtk.orig_macro:find(J_pattern, 1, true)

    if not j_index and not J_index then
        return false, string.format("No matching j%s or J%s found", c, c)
    end


    if j_index and (not J_index or j_index < J_index) then
        -- This is a forward jump
        if not mtk.jump_context[c] then
            mtk.jump_context[c] = {}
        end
        table.insert(mtk.jump_context[c], current_index + 2)
        return J_index and (J_index + 2) or #mtk.orig_macro + 1
    else
        -- This is a backward jump (or the start of a loop)
        local end_index = mtk.orig_macro:find(string.format("[rjJ]%s", c), J_index + 2)
        if not end_index then
            return false, string.format("No matching end for J%s found", c)
        end
        local sub_macro = mtk.orig_macro:sub(J_index + 2, end_index - 1)

        if not mtk.jump_context[c] then
            mtk.jump_context[c] = {}
        end
        table.insert(mtk.jump_context[c], current_index + 2)

        local loop_count = mtk.jump_list[hex + 1] or 1
        if loop_count > 1 then
            -- This is a feature not a bug
            -- in `J0mfj0` with a -j of 2 you would expect 2x `mf`
            -- but you get 3x `mf` because there is a `mf` before getting to the j0
            -- subtract 1 to make it more intuitive
            loop_count = loop_count - 1
        end
        local success, error_message = mtk.execute_macro(sub_macro, loop_count)
        if not success then
            return false, error_message
        end

        table.remove(mtk.jump_context[c])
        if #mtk.jump_context[c] == 0 then
            mtk.jump_context[c] = nil
        end

        return current_index + 2
    end
end})

-- Return function
table.insert(macro_functions, {"r", function(c, macro, current_index)
    local hex = tonumber(c, 16)
    if not hex or hex < 0 or hex > 15 then
        return false, "Invalid return argument: " .. c
    end

    if not mtk.jump_context[c] or #mtk.jump_context[c] == 0 then
        return false, "No matching jump context found"
    end

    -- Get the return index from the context
    local return_index = table.remove(mtk.jump_context[c])
    if #mtk.jump_context[c] == 0 then
        mtk.jump_context[c] = nil
    end
    
    return return_index
end})

-- Quit function
table.insert(macro_functions, {"q", function(c)
    debug_print("Quit")
    mtk.quit_flag = true
    return true
end})

function mtk.execute_macro(macro, loop_count)
    loop_count = loop_count or 1
    
    if not mtk.orig_macro then
        mtk.orig_macro = macro
    else
    end
    
    for loop = 1, loop_count do
        local index = 1
        while index <= #macro do
            local main_code = macro:sub(index, index)
            local sub_code = macro:sub(index + 1, index + 1)
            
            local func = nil
            for _, f in ipairs(macro_functions) do
                if f[1] == main_code then
                    func = f[2]
                    break
                end
            end
            
            if func then
                local result, error_message = func(sub_code, macro, index)
                if error_message then
                    return false, string.format("Error at index %d: %s", index, error_message)
                elseif type(result) == "number" then
                    index = result
                else
                    index = index + 2
                end
            else
                index = index + 2
            end
            
            if mtk.quit_flag then
                return true
            end
        end
    end
    return true
end

-- Command-line interface
local function print_usage()
    print("Usage: mtk [-m <macro_string>] [-l <loop_count>] [-v] [-t] [-S <save_path>] [-s <load_path>] [-j <jump_list>]")
    io.read()
    print("  -m, --macro    Macro string (required unless -t is used)")
    print("  -l, --loop     Number of times to loop the macro (optional, default: 1)")
    print("  -v, --verbose  Enable debug output")
    print("  -t, --test     Enter test interface (REPL mode)")
    print("  -S <path>      Serialize and save inventory snapshot to file")
    print("  -s <path>      Load inventory snapshot from file")
    print("  -j <list>      Comma-separated list of numbers for jump list")
    io.read()
    print("  -f <file>      Load arguments from file")
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

function parseFile(fileName)
    function string.trim(s)
        return s:match("^%s*(.-)%s*$")
    end
    
    function string.split(inputString)
        local words = {}
        for word in inputString:gmatch("%S+") do
            table.insert(words, word)
        end
        return unpack(words)
    end

    -- Add .mtk extension if there's no extension
    if not fileName:match("%.%w+$") then
        fileName = fileName .. ".mtk"
    end

    -- Check if the file exists in the current directory
    debug_print("Checking for file:"..fileName)
    if not fs.exists(fileName) then
        -- If not, check in the /mtk/ directory
        fileName = "/mtk/" .. fileName
        if not fs.exists(fileName) then
            error("File not found: " .. fileName)
        end
    end

    local file = fs.open(fileName, "r")
    if not file then
        error("Could not open file: " .. fileName)
    end

    local arguments = {}
    local currentValue = nil

    for line in file.readLine do
        line = line:trim()
        if #line > 0 and line:sub(1, 1) ~= "#" then
            if currentValue and line:sub(1,1)== "-" then 
                for word in currentValue:gmatch("%S+") do
                    table.insert(arguments, word)
                end
                currentValue = line
            elseif currentValue then
                currentValue = currentValue .. line -- add the new line
            else
                currentValue = line
            end
        end
    end
    if currentValue then 
        for word in currentValue:gmatch("%S+") do
            table.insert(arguments, word)
        end
    end
    file.close()
    return arguments
end

-- Initialize arg_handlers as an empty table
local arg_handlers = {}

-- Help handler
table.insert(arg_handlers, {
    flags = {"-h", "--help"},
    handler = function(args, i, config)
        print_usage()
        return i, true  -- Return true to indicate execution should stop
    end
})

-- Macro string handler
table.insert(arg_handlers, {
    flags = {"-m", "--macro"},
    handler = function(args, i, config)
        i = i + 1
        config.macro_string = args[i]
        return i
    end
})

-- Loop count handler
table.insert(arg_handlers, {
    flags = {"-l", "--loop"},
    handler = function(args, i, config)
        i = i + 1
        config.loop_count = tonumber(args[i])
        return i
    end
})

-- Verbose mode handler
table.insert(arg_handlers, {
    flags = {"-v", "--verbose"},
    handler = function(args, i, config)
        mtk.debug = true
        if lib_debug then
            lib_debug.set_verbose(true)
        end
        return i
    end
})

-- Test mode handler
table.insert(arg_handlers, {
    flags = {"-t", "--test"},
    handler = function(args, i, config)
        config.test_mode = true
        return i
    end
})

-- Save snapshot handler
table.insert(arg_handlers, {
    flags = {"-S"},
    handler = function(args, i, config)
        i = i + 1
        config.save_path = args[i]
        return i
    end
})

-- Load snapshot handler
table.insert(arg_handlers, {
    flags = {"-s"},
    handler = function(args, i, config)
        i = i + 1
        config.load_path = args[i]
        return i
    end
})

-- Jump list handler
table.insert(arg_handlers, {
    flags = {"-j"},
    handler = function(args, i, config)
        i = i + 1
        mtk.jump_list = {}
        for num in args[i]:gmatch("([^,]+)") do
            if num == "" then
                table.insert(mtk.jump_list, nil)
            else
                table.insert(mtk.jump_list, tonumber(num))
            end
        end
        return i
    end
})

-- File input handler
table.insert(arg_handlers, {
    flags = {"-f"},
    handler = function(args, i, config)
        i = i + 1
        local fileName = args[i]
        local fileArgs = parseFile(fileName)
        for j, argPair in ipairs(fileArgs) do
            debug_print("Adding arg:" .. argPair)
            table.insert(args, i + j, argPair)
        end
        return i
    end
})

function mtk.run_cli(args)
    local config = {
        macro_string = nil,
        loop_count = 1,
        test_mode = false,
        save_path = nil,
        load_path = nil
    }
    mtk.jump_list = {}  -- Initialize jump_list

    local i = 1
    while i <= #args do
        local handled = false
        for _, handler in ipairs(arg_handlers) do
            for _, flag in ipairs(handler.flags) do
                if args[i] == flag then
                    local new_i, should_return = handler.handler(args, i, config)
                    i = new_i
                    handled = true
                    if should_return then
                        return
                    end
                    break
                end
            end
            if handled then break end
        end
        if not handled then
            print("Unknown argument: " .. args[i])
            io.read()
            print_usage()
            return
        end
        i = i + 1
    end

    if config.load_path then
        if not deserialize_snapshot(config.load_path) then
            print("Failed to load inventory snapshot from " .. config.load_path)
            return
        end
    else
        take_inventory_snapshot()
    end

    if config.save_path then
        if not serialize_snapshot(config.save_path) then
            print("Failed to save inventory snapshot to " .. config.save_path)
            return
        end
    end

    if config.test_mode then
        run_test_interface()
    elseif not config.macro_string then
        print("Error: Macro string is required unless in test mode")
        print_usage()
        return
    else
        mtk.execute_macro(config.macro_string, config.loop_count)
    end
end

-- Check if this script is being run directly
if arg ~= nil and #arg > 0 then
    mtk.run_cli(arg)
else
    isLoaded_as_module = true
    debug_print("mtk.lua loaded as a module")
end

-- Module interface
return setmetatable(mtk, {
    __call = function(_, macro_string, loop_count)
        mtk.orig_macro = nil  -- Reset orig_macro before each execution
        return mtk.execute_macro(macro_string, loop_count)
    end
})