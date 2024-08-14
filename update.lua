-- update.lua

-- List of URLs to download from
local urls = {
    "https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/lib_ssh.lua",
    "https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/tSSH.lua",
    "https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/tSSHd.lua",
    "https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/tSCP.lua"
}

-- Function to extract filename from URL
local function getFilename(url)
    return url:match("^.+/(.+)$")
end

-- Function to get desired filename (without .lua extension)
local function getDesiredFilename(filename)
    return filename:gsub("%.lua$", "")
end

-- Function to update a single file
local function updateFile(url)
    local filename = getFilename(url)
    local desiredFilename = getDesiredFilename(filename)
    print("Updating " .. desiredFilename)

    -- Delete the file if it exists (both with and without .lua extension)
    if fs.exists(desiredFilename) then
        fs.delete(desiredFilename)
        print("  Deleted existing file")
    end
    if fs.exists(filename) then
        fs.delete(filename)
        print("  Deleted existing .lua file")
    end

    -- Download the new file
    local success, error = shell.run("wget", url)
    if success then
        -- Rename the file to remove the .lua extension
        fs.move(filename, desiredFilename)
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