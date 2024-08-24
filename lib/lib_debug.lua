local lib_debug = {}

-- Global verbose flag
lib_debug.verbose = false

-- Debug print function
function lib_debug.print_debug(...)
    if lib_debug.verbose then
        print(...)
    end
end

-- Function to set verbose mode
function lib_debug.set_verbose(value)
    lib_debug.verbose = value
end

-- Function to get current verbose mode
function lib_debug.get_verbose()
    return lib_debug.verbose
end

return lib_debug