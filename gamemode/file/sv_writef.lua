FILEW = {}
local fileName = nil
local filePath = nil
local fileBase = nil
local fileWrite = nil

function FILEW:Path(pathway)
    if string.EndsWith(pathway, "\\")
       pathway = string.TrimRight(pathway, "\\")
    end
    filePath = pathway 
end

function FILEW:Name(name)
   fileName = name 
end

function FILEW:Base(base)
   fileBase = base
end



if Server then
    function FILEW:WriteFile()
        file.Write(fileName, fileWrite)
    end
    
    -- These functions should be called last out of all of these
    function FILEW:Write(writeTo)
        fileWrite = writeTo
        self:WriteFile()
    end
    
end

