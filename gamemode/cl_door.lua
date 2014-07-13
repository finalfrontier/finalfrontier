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

local _mt = {}
_mt.__index = _mt

_mt._ship = nil
_mt._rooms = nil

_mt._bounds = nil

_mt._nwdata = nil

function _mt:GetShip()
    return self._ship
end

function _mt:GetName()
    return self._nwdata.name
end

function _mt:GetIndex()
    return self._nwdata.index
end

function _mt:IsPowered()
    return self._nwdata.powered or false
end

function _mt:GetArea()
    return self._nwdata.area
end

function _mt:GetPos()
    return self._nwdata.x, self._nwdata.y
end

function _mt:GetAngle()
    return self._nwdata.angle
end

function _mt:GetRoomNames()
    return self._nwdata.roomnames
end

function _mt:_UpdateRooms()
    local rooms = {}
    for i = 1, 2 do
        local name = self:GetRoomNames()[i]
        local room = ships.GetRoomByName(name)
        room:AddDoor(self)
        rooms[i] = room
        room:GetShip():AddDoor(self)
    end
    self._rooms = rooms
end

function _mt:GetRooms()
    return self._rooms
end

function _mt:_UpdateBounds()
    self._bounds = Bounds()
    for _, v in pairs(self:GetCorners()) do
        self._bounds:AddPoint(v.x, v.y)
    end
end

function _mt:GetBounds()
    return self._bounds
end

function _mt:GetCorners()
    return self._nwdata.corners
end

function _mt:IsOpen()
    return self._nwdata.open
end

function _mt:IsClosed()
    return not self._nwdata.open
end

function _mt:IsLocked()
    return self._nwdata.locked
end

function _mt:IsUnlocked()
    return not self._nwdata.locked
end

function _mt:Think()
    if not self:GetBounds() and self:GetCorners() then
        self:_UpdateBounds()
    end

    if not self:GetRooms() and self:GetRoomNames() then
        self:_UpdateRooms()
    end
end

function _mt:Remove()
    self._nwdata:Forget()
end

function Door(name, ship, index)
    door = {}
    door._ship = ship

    door._nwdata = NetworkTable(name)
    door._nwdata.name = name
    door._nwdata.index = index

    return setmetatable(door, _mt)
end
