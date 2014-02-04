FileA = {}
fileName = nil
filePath = nil
fileBase = "DATA"
fileAppend = nil

function FILEA:Name(name)
  fileName = name
end

function FILEA:Path(pathway)
  filePath = pathway
end

-- Completly Useless but included for sake of base call needed
function FILEA:Base()
  fileBase = "DATA"
end

if Server then
  
    function FILEA:Append()
        fileCheck = file.Read(filePath..fileName, fileBase)
        if fileCheck != nil then 
            fileCheck = string.format(fileCheck.."%", "\n"..fileAppend)
            file.Write(filePath..fileName, fileCheck)
        end
       end
    end
  
end
