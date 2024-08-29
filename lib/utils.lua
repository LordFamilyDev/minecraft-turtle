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

return utils