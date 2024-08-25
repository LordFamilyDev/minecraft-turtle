-- dynamic_update.lua (with local .git file for hash storage)

local repo_owner = "LordFamilyDev"
local repo_name = "minecraft-turtle"
local branch = "main"
local tokenFile = "token"
local github_token = ""
local tArgs = { ... }
local getToken -- Function to read the token from the file
if #tArgs == 1 then
    branch = tArgs[1]
end

local api_url = string.format("https://api.github.com/repos/%s/%s/contents?ref=%s&x=%x", repo_owner, repo_name, branch, math.random(1, 1000000))

-- Rate limiting
local last_request_time = 0
local request_interval = 1 -- Minimum time between requests in seconds

-- Function to get the current time
local function getCurrentTime()
    return os.epoch("utc") / 1000 -- Convert milliseconds to seconds
end

-- Function to wait for rate limit
local function waitForRateLimit()
    local current_time = getCurrentTime()
    local time_since_last_request = current_time - last_request_time
    if time_since_last_request < request_interval then
        sleep(request_interval - time_since_last_request)
    end
    last_request_time = getCurrentTime()
end

local function getToken()
    local tokenFile = ".token"
    local f = fs.open(tokenFile, "r")
    if f ~= nil  then
        github_token = f.readAll()
        f.close()
        return github_token
    else
        f = fs.open("token", "r") 
        if f ~= nil then
            github_token = f.readAll()
            f.close()
        end
        
        if github_token == "" then
            print("Enter your git token:")
            github_token = io.read()
        end
        
        file = fs.open(tokenFile, "w")
        if file ~= nil then
            file.write(github_token)
            file.close()
            print("Token saved to file.")
        else
            print("Unable to save token to file.")
        end
        
        return github_token
    end
end

local function getURL(url)
    waitForRateLimit() -- Implement rate limiting
    local headers = {
        "Authorization: Bearer " .. github_token,
        "X-GitHub-Api-Version: 2022-11-28"
    }
    print("Fetching: " .. url)

    return http.get({
        url = url,
        headers = headers
    })
end

-- Function to load the .git file
local function loadGitFile()
    if fs.exists(".git") then
        local file = fs.open(".git", "r")
        local content = file.readAll()
        file.close()
        return textutils.unserializeJSON(content) or {}
    end
    return {}
end

-- Function to save the .git file
local function saveGitFile(gitData)
    local file = fs.open(".git", "w")
    file.write(textutils.serializeJSON(gitData))
    file.close()
end

-- Modified downloadFile function to use .git file for hash comparison
local function downloadFile(url, path, sha, gitData)
    print("Checking: " .. path)
    local current_hash = gitData[path]
    
    if current_hash == sha then
        print("  File unchanged, skipping download")
        return false
    end
    
    print("Downloading: " .. path)
    local response, str, failResp = getURL(url)
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
        
        -- Update gitData
        gitData[path] = sha
        return true
    else
        print("Failed to download: ")
        print(str)
        print(failResp.readAll)
        return false
    end
end

-- Modified processContents function
local function processContents(contents, base_path, recursion, gitData)
    if recursion > 5 then
        print("Recursion limit reached")
        return false
    end
    local changes_made = false
    for _, item in ipairs(contents) do
        print("Processing: " .. item.path .. " (" .. item.type .. ")".. " (" .. item.name .. ")")
        local path = item.path
        if item.type == "file" then
            local file_changed = downloadFile(item.download_url .. "?rand=".. math.random(1,1000), path, item.sha, gitData)
            changes_made = changes_made or file_changed
        elseif item.type == "dir" then
            -- Recursively process subdirectories
            waitForRateLimit() -- Implement rate limiting
            local response = getURL(item.url .. "&rand=".. math.random(1,1000))
            if response then
                local subdir_contents = textutils.unserializeJSON(response.readAll())
                response.close()
                local subdir_changes = processContents(subdir_contents, path, recursion + 1, gitData)
                changes_made = changes_made or subdir_changes
            else
                print("Failed to fetch contents of: " .. path)
            end
        end
    end
    return changes_made
end

-- Main update process
print("Starting dynamic update process...")
github_token = getToken()
print("Using token: " .. github_token)
print("Fetching from: " .. api_url)

-- Load existing .git file
local gitData = loadGitFile()

-- Fetch repository contents
local response, str, failResp = getURL(api_url)
if response then
    local contents = textutils.unserializeJSON(response.readAll())
    response.close()
    
    -- Process and download files
    local changes_made = processContents(contents, "", 0, gitData)
    
    -- Save updated .git file
    if changes_made then
        saveGitFile(gitData)
        print("Update process completed. Changes were made.")
        os.reboot()
    else
        print("Update process completed. No changes were necessary.")
    end
else
    print("Failed to fetch repository contents:")
    print(str)
    print(failResp.readAll)
end