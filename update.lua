-- dynamic_update.lua

-- GitHub API URL for the repository contents
local repo_owner = "LordFamilyDev"
local repo_name = "minecraft-turtle"
local branch = "main"
local tArgs = { ... }
if #tArgs = 1 then
    branch = tArgs[1]
end

local api_url = string.format("https://api.github.com/repos/%s/%s/contents?ref=%s", repo_owner, repo_name, branch)

-- Function to download a file
local function downloadFile(url, path)
    print("Downloading: " .. path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        -- Ensure the directory exists
        local dir = fs.getDir(path)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Write the file
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        print("  Downloaded successfully")
    else
        print("  Failed to download")
    end
end

-- Function to process repository contents
local function processContents(contents, base_path)
    for _, item in ipairs(contents) do
        local path = fs.combine(base_path, item.name)
        if item.type == "file" then
            downloadFile(item.download_url, path)
        elseif item.type == "dir" then
            -- Recursively process subdirectories
            local subdir_url = api_url .. "&path=" .. item.path
            local response = http.get(subdir_url)
            if response then
                local subdir_contents = textutils.unserializeJSON(response.readAll())
                response.close()
                processContents(subdir_contents, path)
            else
                print("Failed to fetch contents of: " .. path)
            end
        end
    end
end

-- Main update process
print("Starting dynamic update process...")

-- Fetch repository contents
local response = http.get(api_url)
if response then
    local contents = textutils.unserializeJSON(response.readAll())
    response.close()
    
    -- Process and download files
    processContents(contents, "")
    
    print("Update process completed.")
else
    print("Failed to fetch repository contents.")
end