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

_mt._roomdict = nil
_mt._roomlist = nil
_mt._doorlist = nil

_mt._systems = nil

_mt._bounds = nil

_mt._nwdata = nil

_mt._valid = true

function _mt:IsCurrent()
    return self._valid and self:GetName() and self._nwdata:IsCurrent()
        and self:GetBounds() and self:GetRange()
        and table.Count(self:GetRooms()) >= table.Count(self:GetRoomNames())
        and table.Count(self:GetDoors()) >= table.Count(self:GetDoorNames())
end

function _mt:IsValid()
    return self._valid
end

function _mt:GetName()
    return self._nwdata.name
end

function _mt:GetObject()
    if IsValid(self._nwdata.object) and self._nwdata.object.GetObjectType then
        return self._nwdata.object
    else
        return nil
    end
end

function _mt:GetHazardMode()
    return self._nwdata.hazardmode
end

function _mt:IsObjectInRange(obj)
    if not IsValid(obj) or not obj.GetObjectType then return false end
    
    local ox, oy = obj:GetCoordinates()
    local sx, sy = self:GetCoordinates()

    return universe:GetDistance(ox, oy, sx, sy) <= self:GetRange()
end

function _mt:GetCoordinates()
    if self:GetObject() and self:GetObject():IsValid() then
        return self:GetObject():GetCoordinates()
    else
        return 0, 0
    end
end

function _mt:GetRotation()
    return self._nwdata.object:GetRotation()
end

function _mt:GetRotationRadians()
    return self._nwdata.object:GetRotationRadians()
end

function _mt:GetVel()
    return self._nwdata.object:GetVel()
end

function _mt:GetRange()
    local sensors = self:GetSystem("sensors")
    if not sensors then return 0.1 end
    return sensors:GetRange()
end

function _mt:_UpdateBounds()
    local bounds = Bounds()
    for _, room in pairs(self:GetRooms()) do
        if not room:GetBounds() then return end
        bounds:AddBounds(room:GetBounds())
    end
    self._bounds = bounds
end

function _mt:GetBounds()
    return self._bounds
end

function _mt:GetOrigin()
    return self._nwdata.x, self._nwdata.y
end

function _mt:GetFullName()
    return self._nwdata.fullname or "Unnamed"
end

function _mt:GetUIColor()
    return self._nwdata.uicolor or Color(255, 255, 255, 255)
end

function _mt:GetRoomNames()
    return self._nwdata.roomnames or {}
end

function _mt:_UpdateRooms()
    for index, name in pairs(self:GetRoomNames()) do
        if self._roomdict[name] then return end

        local room = Room(name, self, index)
        self._roomdict[name] = room
        self._roomlist[index] = room
    end
end

function _mt:GetRooms()
    return self._roomlist
end

function _mt:GetRoomByName(name)
    return self._roomdict[name]
end

function _mt:GetRoomByIndex(index)
    return self._roomlist[index]
end

function _mt:GetSystem(name)
    if not self._systems[name] then
        for _, room in pairs(self._roomlist) do
            if room:GetSystemName() == name then
                self._systems[name] = room:GetSystem()
                return room:GetSystem()
            end
        end
    end

    return self._systems[name]
end

function _mt:_UpdateDoors()
    for index, name in pairs(self:GetDoorNames()) do
        if self._doorlist[index] then return end
        
        self._doorlist[index] = Door(name, self, index)
    end
end

function _mt:AddDoor(door)
    self._doorlist[door:GetIndex()] = door
end

function _mt:GetDoorNames()
    return self._nwdata.doornames or {}
end

function _mt:GetDoors()
    return self._doorlist
end

function _mt:GetDoorByIndex(index)
    return self._doorlist[index]
end

function _mt:GetDoorByName(name)
    for _, door in pairs(self:GetDoors()) do
        if door:GetName() == name then return door end
    end
    return nil
end

function _mt:FindTransform(screen, x, y, width, height)
    local bounds = Bounds(x, y, width, height)
    return FindBestTransform(self:GetBounds(), bounds, true, true)
end

function _mt:ApplyTransform(transform)
    for _, room in pairs(self:GetRooms()) do
        room:ApplyTransform(transform)
    end

    for _, door in ipairs(self:GetDoors()) do
        door:ApplyTransform(transform)
    end
end

function _mt:Think()
    if not self._valid then return end

    if table.Count(self:GetRooms()) < table.Count(self:GetRoomNames()) then
        self:_UpdateRooms()
    end

    if table.Count(self:GetDoors()) < table.Count(self:GetDoorNames()) then
        self:_UpdateDoors()
    end

    if not self:GetBounds() and table.Count(self:GetRoomNames()) > 0 and
        table.Count(self:GetRooms()) == table.Count(self:GetRoomNames()) then
        self:_UpdateBounds()
    end

    for _, room in pairs(self:GetRooms()) do
        room:Think()
    end

    for _, door in ipairs(self:GetDoors()) do
        door:Think()
    end

    local ply = LocalPlayer()
    if self == ply:GetShip() then
        if self:GetHazardMode() and not ply._hazardalarm then
            local sound = CreateSound(ply, "ambient/alarms/apc_alarm_loop1.wav")
            sound:PlayEx(0.25, 100)
            ply._hazardalarm = sound
            ply._hazardship = self
        elseif ply._hazardalarm and (not self:GetHazardMode() or ply._hazardship ~= self) then
            ply._hazardalarm:FadeOut(1)
            ply._hazardalarm = nil
            ply._hazardship = nil
        end
    end
end

function _mt:Remove()
    self._valid = false
    self._nwdata:Forget()

    for _, room in pairs(self:GetRooms()) do
        room:Remove()
    end

    for _, door in ipairs(self:GetDoors()) do
        door:Remove()
    end
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetShip()
    local shipname = self:GetShipName()
    if not shipname or string.len(shipname) == 0 then return nil end
    return ships.GetByName(shipname)
end

function Ship(name)
    local ship = {}

    ship._roomdict = {}
    ship._roomlist = {}
    ship._doorlist = {}

    ship._systems = {}

    ship._nwdata = NetworkTable(name)
    ship._nwdata.name = name

    return setmetatable(ship, _mt)
end
