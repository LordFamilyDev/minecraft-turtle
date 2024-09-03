-- Function to perform an HTTP GET request with JSON header and error handling
local function http_get_json(url)
    local response, error = http.get(url, {["Accept"] = "application/json"})
    if error then
        return nil, "Network error: " .. tostring(error)
    elseif not response then
        return nil, "Failed to connect to the server"
    elseif response.getResponseCode() ~= 200 then
        local err_msg = "HTTP error " .. response.getResponseCode()
        response.close()
        return nil, err_msg
    end
    return response
end

-- Function to load the update info
local function load_update_info()
    local update_info_path = ".updateInfo.json"
    if fs.exists(update_info_path) then
        local file = fs.open(update_info_path, "r")
        local content = file.readAll()
        file.close()
        return textutils.unserializeJSON(content)
    end
    return nil
end

-- Function to save the update info
local function save_update_info(info)
    local update_info_path = ".updateInfo.json"
    local file = fs.open(update_info_path, "w")
    file.write(textutils.serializeJSON(info))
    file.close()
end

-- Function to prompt user for URL
local function prompt_for_url()
    print("Usage:")
    print("URL is stored in: .updateInfo.json")
    print("if file is present, update will pull from last source used")
    print("-m : resets to main branch")
    print("-b <branch> : switches to branch")
    print("-w <user> : switches to users wip folder")
    print("-u <custom URL> : switches to custom url")


    print("Please enter the root URL for the files tree:")
    return read()
end

-- Function to parse command-line arguments
local function parse_args(args)
    local url = nil
    local i = 1
    while i <= #args do
        if args[i] == "-m" then
            url = "https://turtles.lordylordy.org/code/main/"
        elseif args[i] == "-b" and i < #args then
            local branch = args[i + 1]
            url = "https://turtles.lordylordy.org/code/" .. branch .. "/"
            i = i + 1
        elseif args[i] == "-w" and i < #args then
            local user = args[i + 1]
            url = "https://turtles.lordylordy.org/wip/" .. user .. "/"
            i = i + 1
        elseif args[i] == "-u" and i < #args then
            url = args[i + 1]
            i = i + 1
        end
        i = i + 1
    end
    return url
end

-- Function to download a file
local function download_file(url, path)
    local response, error = http_get_json(url)
    if response then
        local content = response.readAll()
        response.close()
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        print("Downloaded: " .. path)
        return true
    else
        print("Failed to download " .. path .. ": " .. error)
        return false
    end
end

-- Function to load the existing .listing.json file
local function load_listing(path)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local content = file.readAll()
        file.close()
        return textutils.unserializeJSON(content)
    end
    return {}
end

-- Function to save the .listing.json file
local function save_listing(path, listing)
    local file = fs.open(path, "w")
    file.write(textutils.serializeJSON(listing))
    file.close()
end

-- Function to check if a file needs updating
local function needs_update(old_info, new_info)
    return old_info == nil or
           old_info.mod_time ~= new_info.mod_time or
           old_info.size ~= new_info.size
end

-- Function to recursively process directory
local function process_directory(base_url, dir_path, files)
    local listing_path = fs.combine(dir_path, ".listing.json")
    local existing_listing = load_listing(listing_path)
    local updated_listing = {}
    
    for _, file in ipairs(files) do
        local full_path = fs.combine(dir_path, file.name)
        if file.is_dir then
            if not fs.exists(full_path) then
                print("Creating directory: " .. full_path)
                fs.makeDir(full_path)
            end
            -- Recursively process subdirectory
            local sub_url = base_url .. file.name .. "/"
            local sub_response, sub_error = http_get_json(sub_url)
            if sub_response then
                local sub_data = sub_response.readAll()
                sub_response.close()
                local sub_files = textutils.unserializeJSON(sub_data)
                if sub_files then
                    process_directory(sub_url, full_path, sub_files)
                else
                    print("Failed to parse JSON for subdirectory " .. full_path)
                end
            else
                print("Failed to fetch subdirectory " .. full_path .. ": " .. sub_error)
            end
        elseif needs_update(existing_listing[file.name], file) then
            local success = download_file(base_url .. file.name, full_path)
            if success then
                updated_listing[file.name] = file
            end
        else
            print("Skip file: " .. full_path)
            updated_listing[file.name] = existing_listing[file.name]
        end
    end
    
    save_listing(listing_path, updated_listing)
    print("Updated dir: " .. dir_path)
end

-- Main function
local function main(args)
    -- Parse command-line arguments
    local arg_url = parse_args(args)

    -- Load or prompt for the JSON URL
    local update_info = load_update_info()
    if arg_url then
        update_info = {json_url = arg_url}
        save_update_info(update_info)
    elseif not update_info or not update_info.json_url then
        local json_url = prompt_for_url()
        update_info = {json_url = json_url}
        save_update_info(update_info)
    end

    print("Fetching JSON data from " .. update_info.json_url .. "...")
    local response, error = http_get_json(update_info.json_url)
    
    if not response then
        print("Failed to fetch JSON data: " .. error)
        return
    end

    local data = response.readAll()
    response.close()

    local files = textutils.unserializeJSON(data)
    if not files then
        print("Failed to parse JSON data")
        return
    end

    print("Processing files and directories...")
    process_directory(update_info.json_url, "", files)

    print("File update process completed!")
    shell.run("/startup.lua")
end

-- Run the main function with command-line arguments
main({...})