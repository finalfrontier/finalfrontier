if SERVER then AddCSLuaFile("sh_object.lua") end

if not obj then
    obj = {}
    obj._dict = {}
else return end

local _mt = {}
_mt.__index = _mt

_mt._nwdata = nil

_mt.Name = "unnamed"

_mt._sector = nil

function _mt:Initialize()
    return
end

function _mt:GetSector()
    return self._sector
end

function _mt:GetOrigin()
    return self._nwdata.x, self._nwdata.y
end

function _mt:Think(dt)
    return
end

if SERVER then
    function _mt:SetSector(sector)
        self._sector = sector
    end

    function _mt:Move(x, y)
        self._nwdata.x = self._nwdata.x + x
        self._nwdata.y = self._nwdata.y + y        

        self._nwdata.x = self._nwdata.x - math.floor(self._nwdata.x / 24) * 24
        self._nwdata.y = self._nwdata.y - math.floor(self._nwdata.y / 24) * 24
    end

    function _mt:_UpdateNWData()
        self._sector:_UpdateNWData()
    end
elseif CLIENT then
    function _mt:Draw()
        return
    end
end

MsgN("Loading objects...")
local files = file.Find("finalfrontier/gamemode/objects/*.lua", "LUA")
for i, file in ipairs(files) do 
    local name = string.sub(file, 0, string.len(file) - 4)
    if SERVER then AddCSLuaFile("objects/" .. file) end

    MsgN("  Loading object class " .. name)

    OBJ = { Name = name }
    OBJ.__index = OBJ
    OBJ.Super = {}
    OBJ.Super.__index = OBJ.Super
    OBJ.Super[name] = OBJ
    include("objects/" .. file)

    obj._dict[name] = OBJ
    OBJ = nil
end

for _, OBJ in pairs(obj._dict) do
    if OBJ.BaseName then
        OBJ.Base = obj._dict[OBJ.BaseName]
        setmetatable(OBJ, OBJ.Base)
        setmetatable(OBJ.Super, OBJ.Base.Super)
    else
        setmetatable(OBJ, _mt)
    end
end

if SERVER then
    function obj.Create(class, x, y)
        if obj._dict[class] then
            local sector = universe.GetSector(x, y)

            x = x - math.floor(x / 24) * 24
            y = y - math.floor(y / 24) * 24

            local object = setmetatable({ _nwdata = { class = class, x = x, y = y } }, obj._dict[class])

            sector:AddObject(object)
            object:Initialize()
            
            return object
        end
    end
elseif CLIENT then
    function obj.Create(table)
        if obj._dict[table.class] then
            local sector = universe.GetSector(table.x, table.y)
            local object = setmetatable({ _nwdata = table }, obj._dict[table.class])

            sector:AddObject(object)
            object:Initialize()
            
            return object
        end
    end
end
