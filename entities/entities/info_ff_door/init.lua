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

local TEMPERATURE_TRANSMIT_RATE = 0.05
local ATMOSPHERE_TRANSMIT_RATE = 40.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT._rooms = nil
ENT._doorEnts = nil

ENT._lastupdate = 0

ENT._nwdata = nil

function ENT:KeyValue(key, value)
    self._nwdata = self._nwdata or {}

    if key == "room1" then
        self:_SetRoomName(1, tostring(value))
    elseif key == "room2" then
        self:_SetRoomName(2, tostring(value))
    end
end

function ENT:Initialize()
    self._nwdata = NetworkTable(self:GetName(), self._nwdata)

    self._rooms = {}

    self._nwdata.roomnames = self._nwdata.roomnames or {}
    self._nwdata.name = self:GetName()
    self._nwdata:Update()

    self:_SetArea(4)
end

function ENT:InitPostEntity()
    local name = self:GetName()
    local doorName = string.Replace(name, "_info_", "_")

    self._doorEnts = ents.FindByName(doorName)

    local coords = {
        { x = -32, y = -64 },
        { x = -32, y =  64 },
        { x =  32, y =  64 },
        { x =  32, y = -64 }
    }

    local trans = Transform2D()
    trans:Rotate(self:GetAngles().y * math.pi / 180)
    local pos = self:GetPos()
    trans:Translate(pos.x, pos.y)

    self._nwdata.corners = {}
    for i, v in ipairs(coords) do
        local x, y = trans:Transform(v.x, v.y)
        self._nwdata.corners[i] = { x = x, y = y }
    end
    self._nwdata:Update()

    self:_UpdateRooms()

    self:_NextUpdate()
end

function ENT:Reset()
    self:Unlock()
end

function ENT:SetIsPowered(powered)
    self._nwdata.powered = powered
    self._nwdata:Update()
end

function ENT:IsPowered()
    return self._nwdata.powered or false
end

function ENT:_SetArea(area)
    self._nwdata.area = area
    self._nwdata:Update()
end

function ENT:GetArea()
    return self._nwdata.area or 4
end

function ENT:SetIndex(index)
    self._nwdata.index = index
    self._nwdata:Update()
end

function ENT:GetIndex()
    return self._nwdata.index
end

function ENT:_SetRoomName(index, name)
    if not self._nwdata.roomnames then self._nwdata.roomnames = {} end

    if index < 1 or index > 2 then return end

    self._nwdata.roomnames[index] = name
end

function ENT:GetRoomNames()
    return self._nwdata.roomnames
end

function ENT:_UpdateRooms()
    for i = 1, 2 do
        local name = self:GetRoomNames()[i]
        if not name then
            print("Door \"" .. self:GetName() ..
                "\" has a missing room association #" .. tostring(i))
        else
            local rooms = ents.FindByName(name)
            if #rooms > 0 then
                local room = rooms[1]
                room:AddDoor(self)
                self._rooms[i] = room
                room:GetShip():AddDoor(self)
            end
        end
    end
end

function ENT:GetRooms()
    return self._rooms
end

function ENT:AcceptInput(name, activator, caller, data)
    if name == "Opened" then
        self._nwdata.open = true
        self._nwdata:Update()
    elseif name == "Closed" then
        self._nwdata.open = false
        self._nwdata:Update()
    end
end

function ENT:Open()
    if self:IsUnlocked() and self:IsClosed() then
        for _, ent in ipairs(self._doorEnts) do
            ent:Fire("Open", "", 0)
        end
    end
end

function ENT:Close()
    if self:IsUnlocked() and self:IsOpen() then
        for _, ent in ipairs(self._doorEnts) do
            ent:Fire("Close", "", 0)
        end
    end
end

function ENT:Lock()
    if self:IsUnlocked() then
        self._nwdata.locked = true
        self._nwdata:Update()
        self:EmitSound("doors/door_metal_large_close2.wav", SNDLVL_STATIC, 100)
    end
end

function ENT:Unlock()
    if self:IsLocked() then
        self._nwdata.locked = false
        self._nwdata:Update()
        self:EmitSound("doors/door_metal_large_open1.wav", SNDLVL_STATIC, 100)
    end
end

function ENT:ToggleLock()
    if self:IsLocked() then
        self:Unlock()
    else
        self:Lock()
    end
end

function ENT:LockOpen()
    self:Unlock()
    self:Open()
    self:Lock()
end

function ENT:UnlockClose()
    self:Unlock()
    self:Close()
end

function ENT:_NextUpdate()
    local curTime = CurTime()
    local dt = curTime - self._lastupdate
    self._lastupdate = curTime

    return dt
end

function ENT:Think()
    local dt = self:_NextUpdate()
    
    local rooms = self:GetRooms()

    if #rooms < 2 then return end
    
    if self:IsOpen() then    
        -- Temperature transfer
        local roomA = rooms[1]
        local roomB = rooms[2]
        if roomA:GetTemperature() < roomB:GetTemperature() then
            roomA = rooms[2]
            roomB = rooms[1]
        end

        local delta = (roomA:GetTemperature() - roomB:GetTemperature())
            * self:GetArea() * TEMPERATURE_TRANSMIT_RATE * dt

        if delta > 0 then
            roomA:TransmitTemperature(roomB, delta)
        end
        
        -- Atmosphere transfer
        roomA = rooms[1]
        roomB = rooms[2]
        if roomA:GetAtmosphere() < roomB:GetAtmosphere() then
            roomA = rooms[2]
            roomB = rooms[1]
        end

        delta = (roomA:GetAtmosphere() - roomB:GetAtmosphere())
            * self:GetArea() * ATMOSPHERE_TRANSMIT_RATE * dt

        if delta > 0 then
            roomA:TransmitAir(roomB, delta)
        end
    end
end

function ENT:IsOpen()
    return self._nwdata.open
end

function ENT:IsClosed()
    return not self._nwdata.open
end

function ENT:IsLocked()
    return self._nwdata.locked
end

function ENT:IsUnlocked()
    return not self._nwdata.locked
end
