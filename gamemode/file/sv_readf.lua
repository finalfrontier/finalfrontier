FILER = {}
local fileName = nil
local filePath = nil
local fileBase = nil
local fileRead = nil

if Server then
    
    function FILER:Path(pathway)
       filePath = pathway 
    end
    
    function FILER:Name(name)
        fileName = name
    end
    
    function FILER:Base(base)
       fileBase = base 
    end
    
    --Call Last
    function FILER:Read()
        if file.Exists(filePath.."\\"..fileName, fileBase) then
            fileRead = file.Read(filePath.."\\"..fileName, fileBase)
        end
    end
    
end
