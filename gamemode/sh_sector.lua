if SERVER then AddCSLuaFile("sh_sector.lua") end

local _mt = {}
_mt.__index = _mt

_mt._nwdata = nil

_mt._bounds = nil
_mt._objects = nil

function _mt:GetOrigin()
    return self._bounds.l, self._bounds.t
end

function _mt:GetSize()
    return self._bounds.r - self._bounds.l
end

function _mt:GetBounds()
    return self._bounds
end

function _mt:GetObjects()
    return self._objects
end

local horzNames = {
    "alpha", "beta",  "gamma",  "delta",   "epsilon", "zeta", "eta",     "theta",
    "iota",  "kappa", "lambda", "mu",      "nu",      "xi",   "omicron", "phi",
    "rho",   "sigma", "tau",    "upsilon", "phi",     "chi",  "psi",     "omega"
}

local vertNames = {
    "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",
    "9",  "10", "11", "12", "13", "14", "15", "16",
    "17", "18", "19", "20", "21", "22", "23", "24"
}

function _mt:GetName()
    local x, y = self:GetOrigin()

    x = x - math.floor(x / 24) * 24
    y = y - math.floor(y / 24) * 24

    return horzNames[x + 1] .. "-" .. vertNames[y + 1]
end

if SERVER then
    function _mt:AddObject(object)
        if object:GetSector() ~= self then
            table.insert(self._objects, object)
            object:SetSector(self)
        end
    end

    function _mt:RemoveObject(object)
        if object:GetSector() == self then
            table.RemoveByValue(self._objects, object)
            object:SetSector(nil)
        end
    end

    function _mt:_UpdateNWData()
        SetGlobalTable(self._nwtablename, self._nwdata)
    end
elseif CLIENT then
    function _mt:Remove()
        ForgetGlobalTable(self._nwtablename)
    end
end

function Sector(x, y)
    x = math.floor(x)
    y = math.floor(y)
    local sector = setmetatable({
        _bounds = Bounds(x, y, 1, 1),
        _objects = {},
        _nwtablename = "sector" .. tostring(x) .. "." .. tostring(y)
    }, _mt)

    if SERVER then
        sector:_UpdateNWData()
    elseif CLIENT then
        sector._nwdata = GetGlobalTable(sector._nwtablename)
    end

    return sector
end
