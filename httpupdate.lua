-- ComputerCraft APIs
local http = http
local fs = fs

local BASE_URL = "https://turtles.lordylordy.org/code/"  -- Replace with your actual base URL
local LISTING_FILE = "code_index.json"
local LOCAL_DIR = "/"  -- Replace with your desired local directory
local LOCAL_LISTING_FILE = LOCAL_DIR .. "local_" .. LISTING_FILE

-- Function to download a file
local function downloadFile(url, path)
    local response = http.get(url)
    if response then
        local file = fs.open(path, "w")
        if file then
            file.write(response.readAll())
            file.close()
            response.close()
            return true
        end
        response.close()
    end
    return false
end

-- Function to read JSON file
local function readJSONFile(path)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        if file then
            local content = file.readAll()
            file.close()
            return textutils.unserializeJSON(content)
        end
    end
    return nil
end

-- Function to write JSON file
local function writeJSONFile(path, data)
    local file = fs.open(path, "w")
    if file then
        file.write(textutils.serializeJSON(data))
        file.close()
        return true
    end
    return false
end

-- Function to update files
local function updateFiles()
    -- Download the new listing file
    if not downloadFile(BASE_URL .. LISTING_FILE, LOCAL_DIR .. LISTING_FILE) then
        print("Failed to download listing file")
        return
    end

    -- Read the new listing file
    local newListing = readJSONFile(LOCAL_DIR .. LISTING_FILE)
    if not newListing then
        print("Failed to parse new listing file")
        return
    end

    -- Read the old listing file if it exists
    local oldListing = readJSONFile(LOCAL_LISTING_FILE) or {}

    -- Check each file and update if necessary
    for filename, info in pairs(newListing) do
        local localPath = LOCAL_DIR .. filename
        local remoteUrl = BASE_URL .. filename

        -- Create directory if it doesn't exist
        local dir = fs.getDir(localPath)
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end

        local needsUpdate = true
        if oldListing[filename] and oldListing[filename].sha256 == info.sha256 then
            needsUpdate = false
        end

        if needsUpdate then
            print("Updating " .. filename)
            if downloadFile(remoteUrl, localPath) then
                print("Successfully updated " .. filename)
            else
                print("Failed to update " .. filename)
            end
        else
            print(filename .. " is up to date")
        end
    end

    -- Save the new listing as the local listing for future comparisons
    writeJSONFile(LOCAL_LISTING_FILE, newListing)
end

-- Run the update function
updateFiles()