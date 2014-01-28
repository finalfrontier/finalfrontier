FILE = {}
fileName = nil
filePath = nil
fileBase = nil
fileWrite = nil

function FILE:Path(pathway)
    if string.EndsWith(pathway, "\\")
       pathway = string.TrimRight(pathway, "\\")
    end
    filePath = pathway 
end

function FILE:Name(name)
   fileName = name 
end

function FILE:Base(base)
   fileBase = base
end



if Server then
    function FILE:WriteFile()
        file.Write(fileName, fileWrite)
    end
    
    -- These functions should be called last out of all of these
    function FILE:Write(writeTo)
        fileWrite = writeTo
        self:WriteFile()
    end
    
end

