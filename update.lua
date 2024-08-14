-- update.lua

-- List of URLs to download from
local urls = {
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/lib_ssh.lua",
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/tSSH.lua",
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/tSSHd.lua",
    "https://raw.githubusercontent.com/caffeineaddiction/minecraft-turtle/main/tSCP.lua"
}

-- Function to extract filename from URL and remove .lua extension
local function getFilename(url)
    local filename = url:match("^.+/(.+)$")
    return filename:gsub("%.lua$", "")
end

-- Function to update a single file
local function updateFile(url)
    local filename = getFilename(url)
    local tempFilename = filename .. ".temp"
    print("Updating " .. filename)

    -- Delete the file if it exists
    if fs.exists(filename) then
        fs.delete(filename)
        print("  Deleted existing file")
    end

    -- Download the new file with a temporary name
    local success, error = shell.run("wget", url, tempFilename)
    if success then
        -- Rename the file to remove the .lua extension
        fs.move(tempFilename, filename)
        print("  Downloaded and renamed successfully")
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