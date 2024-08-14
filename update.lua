-- update.lua

-- List of URLs to download from
local urls = {
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/lib_ssh.lua",
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/tSSH.lua",
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/tSSHd.lua",
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/tSCP.lua"
}

-- Function to extract filename from URL
local function getFilename(url)
    return url:match("^.+/(.+)$")
end

-- Function to update a single file
local function updateFile(url)
    local filename = getFilename(url)
    print("Updating " .. filename)

    -- Delete the file if it exists
    if fs.exists(filename) then
        fs.delete(filename)
        print("  Deleted existing file")
    end

    -- Download the new file
    local success, error = shell.run("wget", url, filename)
    if success then
        print("  Downloaded successfully")
    else
        print("  Failed to download: " .. tostring(error))
    end
end

-- Main update process
print("Starting update process...")
for _, url in ipairs(urls) do
    updateFile(url)
end
print("Update process completed.")