-- /lib/lib_compression.lua

local compression = {}

-- Check if ComputerCraft has native compression algorithms
local hasNativeCompression = false
if compress then
    hasNativeCompression = true
end

-- LZP compression algorithm
local HASH_ORDER = 16
local HASH_SIZE = 1 << HASH_ORDER

local function HASH(h, x)
    return bit.band((h << 4) ~ x, HASH_SIZE - 1)
end

local function lzpCompress(data)
    local output = {"LZP1"}
    local table = {}
    local hash = 0
    
    for i = 1, #data, 8 do
        local chunk = data:sub(i, i + 7)
        local mask = 0
        local unmatched = {}
        
        for j = 1, #chunk do
            local c = string.byte(chunk, j)
            if table[hash] == c then
                mask = mask | (1 << (j - 1))
            else
                table[hash] = c
                unmatched[#unmatched + 1] = string.char(c)
            end
            hash = HASH(hash, c)
        end
        
        output[#output + 1] = string.char(mask)
        output[#output + 1] = table.concat(unmatched)
    end
    
    return table.concat(output)
end

local function lzpDecompress(data)
    if data:sub(1, 4) ~= "LZP1" then
        error("Not a valid LZP compressed stream")
    end
    
    local output = {}
    local table = {}
    local hash = 0
    local i = 5
    
    while i <= #data do
        local mask = string.byte(data, i)
        i = i + 1
        
        for j = 0, 7 do
            local c
            if bit.band(mask, (1 << j)) ~= 0 then
                c = table[hash]
            else
                c = string.byte(data, i)
                i = i + 1
                table[hash] = c
            end
            
            if c then
                output[#output + 1] = string.char(c)
                hash = HASH(hash, c)
            else
                break
            end
        end
    end
    
    return table.concat(output)
end

function compression.compressFiles(basePath, files, output_file)
    local file_data = {}
    
    for _, file in ipairs(files) do
        local fullPath = fs.combine(basePath, file)
        local f = fs.open(fullPath, "r")
        local content = f.readAll()
        f.close()
        
        file_data[#file_data + 1] = {
            path = file,
            content = content
        }
    end
    
    local json_data = textutils.serializeJSON(file_data)
    
    local compressed_data
    if hasNativeCompression then
        compressed_data = compress.gzip(json_data)
    else
        compressed_data = lzpCompress(json_data)
    end
    
    local f = fs.open(output_file, "wb")
    f.write(compressed_data)
    f.close()
end

function compression.decompressFiles(input_file, target_path)
    local f = fs.open(input_file, "rb")
    local compressed_data = f.readAll()
    f.close()
    
    local decompressed_data
    if hasNativeCompression then
        decompressed_data = compress.gunzip(compressed_data)
    else
        decompressed_data = lzpDecompress(compressed_data)
    end
    
    local file_data = textutils.unserializeJSON(decompressed_data)
    
    for _, file in ipairs(file_data) do
        local full_path = fs.combine(target_path, file.path)
        fs.makeDir(fs.getDir(full_path))
        
        local f = fs.open(full_path, "w")
        f.write(file.content)
        f.close()
    end
end

return compression