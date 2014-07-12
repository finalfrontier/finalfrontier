-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

if SERVER then AddCSLuaFile("sh_systems.lua") end

permission = {}
permission.NONE     = 0
permission.ACCESS   = 1
permission.SYSTEM   = 2
permission.SECURITY = 3

if not sys then
    sys = {}
    sys._dict = {}
else return end

local _mt = {}
_mt.__index = _mt

_mt._nwdata = nil

_mt.Name = "unnamed"
_mt.Powered = false

_mt._room = nil
_mt._ship = nil

_mt.SGUIName = "page"

function FindIncrement(current, target, increment)
    if target < current then
        return math.max(target - current, -increment)
    else
        return math.min(target - current, increment)
    end
end

function CalculatePowerCost(current, target, increment, powerPerUnit)
    return powerPerUnit * math.abs(FindIncrement(current, target, increment))
end

function CalculateNextValue(current, target, increment, ratio)
    local inc = FindIncrement(current, target, increment)

    if ratio > 0 then
        return current + inc * ratio
    else
        return current
    end
end

function _mt:Initialize()
    return
end

function _mt:GetRoom()
    return self._room
end

function _mt:GetShip()
    return self._ship
end

if SERVER then
    resource.AddFile("materials/systems/noicon.png")

    _mt._nwtablename = nil

    _mt._power = 0
    _mt._needed = 0

    function _mt:StartControlling(screen, ply)
        return
    end
    
    function _mt:StopControlling(screen, ply)
        return
    end
    
    function _mt:CalculatePowerNeeded()
        return 0
    end

    local function ShouldUpdate(old, new, compare)
        return math.abs(new - old) >= 0.01 or (old ~= new and (old == compare or new == compare))
    end

    function _mt:SetPower(value)
        self._power = value

        if ShouldUpdate(self._nwdata.power or 0, self._power, self._needed) then
            self._nwdata.power = value
            self._nwdata:Update()
        end
    end

    function _mt:GetPower()
        return self._power
    end

    function _mt:SetPowerNeeded(value)
        self._needed = value

        if ShouldUpdate(self._nwdata.needed or 0, self._needed, self._power) then
            self._nwdata.needed = value
            self._nwdata:Update()
        end
    end

    function _mt:GetPowerNeeded()
        return self._needed
    end

    function _mt:GetScreens()
        return self._room:GetScreens()
    end
    
    function _mt:Think(dt)
        return
    end

    function _mt:SetNWValue(ident, value)
        self._nwdata.misc[ident] = value
        self._nwdata:Update()
    end
elseif CLIENT then
    function _mt:GetPower()
        return self._nwdata.power or 0
    end

    function _mt:GetPowerNeeded()
        return self._nwdata.needed or 0
    end

    function _mt:Remove()
        self._nwdata:Forget()
    end

    _mt.Icon = Material("systems/noicon.png", "smooth")
end

function _mt:GetNWValue(ident, default)
    if not self._nwdata.misc then return default end
    return self._nwdata.misc[ident] or default
end

MsgN("Loading systems...")
local files = file.Find("finalfrontier/gamemode/systems/*.lua", "LUA")
for i, file in ipairs(files) do    
    local name = string.sub(file, 0, string.len(file) - 4)
    MsgN("- " .. name)

    if SERVER then AddCSLuaFile("systems/" .. file) end
    
    SYS = setmetatable({ Name = name }, _mt)
    SYS.__index = SYS
    include("systems/" .. file)
    
    sys._dict[name] = SYS
    SYS = nil
end

function sys.GetAll()
    return sys._dict
end

function sys.Create(name, room)
    if string.len(name) == 0 then return nil end
    if sys._dict[name] then
        local system = {
            Base = _mt,
            _room = room,
            _ship = room:GetShip(),
            _nwtablename = room:GetName() .. "_sys"
        }
        setmetatable(system, sys._dict[name])

        system._nwdata = NetworkTable(system._nwtablename)

        if SERVER then
            system._nwdata.misc = {}
            system:SetPower(0)
        end

        system:Initialize()

        if SERVER then system._nwdata:Update() end

        return system
    end
    return nil
end
