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

local ROOM_UPDATE_FREQ = 0.5

local _mt = {}
_mt.__index = _mt
_mt._lastUpdate = 0

_mt._ship = nil
_mt._doorlist = nil
_mt._bounds = nil
_mt._system = nil
_mt._convexPolys = nil

_mt._lerptime = 0

_mt._temperature = nil
_mt._airvolume = nil
_mt._shields = nil

_mt._nwdata = nil

function _mt:IsCurrent()
    return self:GetShip() and self:GetShip():IsValid() and self:GetName() and self._nwdata:IsCurrent()
end

function _mt:GetName()
    return self._nwdata.name
end

function _mt:GetIndex()
    return self._nwdata.index or 0
end

function _mt:GetShip()
    return self._ship
end

function _mt:_UpdateBounds()
    local bounds = Bounds()
    for _, v in ipairs(self:GetCorners()) do
        bounds:AddPoint(v.x, v.y)
    end
    self._bounds = bounds
end

function _mt:GetBounds()
    return self._bounds
end

function _mt:GetSystemName()
    return self._nwdata.systemname
end

function _mt:_UpdateSystem()
    self._system = sys.Create(self:GetSystemName(), self)
end

function _mt:HasSystem()
    return self._system ~= nil
end

function _mt:GetSystem()
    return self._system
end

function _mt:GetVolume()
    return self._nwdata.volume or 0
end

function _mt:GetSurfaceArea()
    return self._nwdata.surfacearea or 0
end

function _mt:AddDoor(door)
    if table.HasValue(self._doorlist, door) then return end

    table.insert(self._doorlist, door)
end

function _mt:GetDoors()
    return self._doorlist
end

function _mt:GetCorners()
    return self._nwdata.corners
end

function _mt:GetDetails()
    return self._nwdata.details
end

function _mt:GetModule(type)
    local index = self._nwdata.modules[type]
    if not index then return nil end
    local mdl = ents.GetByIndex(index)
    if not IsValid(mdl) then return nil end
    return mdl
end

function _mt:GetSlot(module)
    for i, v in pairs(self._nwdata.modules) do
        if v == module:EntIndex() then return i end
    end
    return nil
end

function _mt:_UpdateConvexPolys()
    self._convexPolys = FindConvexPolygons(self:GetCorners())
end

function _mt:GetConvexPolys()
    return self._convexPolys
end

function _mt:_GetLerp()
    return math.Clamp((CurTime() - self._lerptime) / ROOM_UPDATE_FREQ, 0, 1)
end

function _mt:_GetLerpedValue(value)
    return value.old + (value.cur - value.old) * self:_GetLerp()
end

function _mt:_NextValue(value, next)
    value.old = value.cur
    value.cur = next or 0
end

function _mt:GetUnitTemperature()
    return self:_GetLerpedValue(self._temperature)
end

function _mt:GetTemperature()
    return self:GetUnitTemperature() * 600 / self:GetVolume()
end

function _mt:GetAirVolume()
    return self:_GetLerpedValue(self._airvolume)
end

function _mt:GetAtmosphere()
    return self:GetAirVolume() / self:GetVolume()
end

function _mt:GetUnitShields()
    return self:_GetLerpedValue(self._shields)
end

function _mt:GetShields()
    return self:GetUnitShields() / self:GetSurfaceArea()
end

function _mt:GetPowerRatio()
    if self:HasSystem() and self:GetSystem():GetPowerNeeded() > 0 then
        return math.min(1, self:GetSystem():GetPower()
            / self:GetSystem():GetPowerNeeded())
    end
    return 0
end

function _mt:GetPermissionsName()
    return self:GetShip():GetName() .. "_" .. self:GetIndex()
end

function _mt:HasPlayerWithSecurityPermission()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:HasPermission(self, permission.SECURITY, true) then
            return true
        end
    end

    return false
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetRoom()
    local shipName = self:GetShipName()
    if not shipName or string.len(shipName) == 0 then return nil end
    return self:GetShip():GetRoomByIndex(self:GetRoomIndex())
end

function ply_mt:IsInRoom(room)
    return self:GetShipName() == room:GetShip():GetName()
        and self:GetRoomIndex() == room:GetIndex()
end

function _mt:Think()
    if self:_GetLerp() >= 1.0 then
        self:_NextValue(self._temperature, self._nwdata.temperature)
        self:_NextValue(self._airvolume, self._nwdata.airvolume)
        self:_NextValue(self._shields, self._nwdata.shields)

        self._lerptime = CurTime()
    end

    if self:GetSystemName() and not self:GetSystem() then
        self:_UpdateSystem()
    end

    if not self:GetBounds() and self:GetCorners() then
        self:_UpdateBounds()
    end

    if not self:GetConvexPolys() and self:GetCorners() then
        self:_UpdateConvexPolys()
    end
end

function _mt:Remove()
    self._nwdata:Forget()

    if self:GetSystem() then
        self:GetSystem():Remove()
    end
end

function Room(name, ship, index)
    local room = {}

    room._temperature = { old = 0, cur = 0 }
    room._airvolume = { old = 0, cur = 0 }
    room._shields = { old = 0, cur = 0 }

    room._nwdata = NetworkTable(name)
    room._nwdata.name = name
    room._nwdata.index = index

    room._ship = ship
    room._doorlist = {}

    return setmetatable(room, _mt)
end
