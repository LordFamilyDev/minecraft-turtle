local utils = {}


function utils.less(t)
    if type(t) == "table" then
        for i = 1, #t do
            print(t[i])
            if(i%5) then
                io.read()
            end
        end
    else
        for i in t do
            print(i)
            io.read()
        end
    end

end

function utils.readConfig(filename)
    if not fs.exists(filename) then
        return {}
    end
    
    local file = fs.open(filename, "r")
    local content = file.readAll()
    file.close()
    
    local success, result = pcall(textutils.unserializeJSON, content)
    if success then
        return result
    else
        print("Error reading config file: " .. result)
        return {}
    end
end

function utils.saveConfig(filename, config)
    local content = textutils.serializeJSON(config)
    
    local file = fs.open(filename, "w")
    file.write(content)
    file.close()
end

return utils