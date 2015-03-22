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

ENT.Type = "point"
ENT.Base = "base_point"

ENT._roomdict = nil
ENT._roomlist = nil
ENT._doors = nil
ENT._bounds = nil

ENT._defaultGrids = nil

ENT._systems = nil

ENT._players = nil

ENT._nwdata = nil
ENT._object = nil

ENT._mainLightName = nil
ENT._warnLightName = nil
ENT._warnLightBrushName = nil

ENT._mainLights = nil
ENT._warnLights = nil
ENT._warnLightBrushes = nil

ENT._hazardEnd = 0

function ENT:KeyValue(key, value)
    self._nwdata = self._nwdata or {}

    if key == "health" then
        self:_SetBaseHealth(tonumber(value), true)
    elseif key == "name" then
        self:_SetFullName(tostring(value), true)
    elseif key == "color" then
        self:_SetUIColor(tostring(value), true)
    elseif key == "mainlight" then
        self._mainLightName = tostring(value)
    elseif key == "warnlight" then
        self._warnLightName = tostring(value)
    elseif key == "warnlightbrush" then
        self._warnLightBrushName = tostring(value)
    end
end

function ENT:Initialize()
    self._roomdict = {}
    self._roomlist = {}
    self._doors = {}
    self._bounds = Bounds()

    self._systems = {}
    self._players = {}

    self._nwdata = NetworkTable(self:GetName(), self._nwdata)

    self._nwdata.roomnames = {}
    self._nwdata.doornames = {}

    self._nwdata.name = self:GetName()

    self._nwdata.hazardmode = true

    if not self:GetBaseHealth() then
        self:_SetBaseHealth(1)
    end

    self._defaultGrid = GenerateModuleGrid()
end

function ENT:GetDefaultGrid()
    return self._defaultGrid
end

function ENT:GetObject()
    return self._nwdata.object
end

function ENT:IsObjectInRange(obj)
    if not IsValid(obj) or not obj.GetCoordinates then return false end

    local ox, oy = obj:GetCoordinates()
    local sx, sy = self:GetCoordinates()

    return universe:GetDistance(ox, oy, sx, sy) <= self:GetRange()
end

function ENT:GetCoordinates()
    return self._nwdata.object:GetCoordinates()
end

function ENT:GetRotation()
    return self._nwdata.object:GetRotation()
end

function ENT:GetRotationRadians()
    return self._nwdata.object:GetRotationRadians()
end

function ENT:GetVel()
    return self._nwdata.object:GetVel()
end

function ENT:GetRange()
    local sensors = self:GetSystem("sensors")
    if not sensors then return 0.1 end
    return sensors:GetRange()
end

function ENT:InitPostEntity()
    self._nwdata.object = ents.Create("info_ff_object")
    self._nwdata.object:SetCoordinates(5 + math.random() * 0.2 - 0.1, 9 + math.random() * 0.2 - 0.1)
    self._nwdata.object:SetObjectType(objtype.SHIP)
    self._nwdata.object:SetObjectName(self:GetName())
    self._nwdata.object:Spawn()
    self._nwdata.object:SetRotation(math.random() * 360)
    self._nwdata:Update()

    self._mainLights = ents.FindByName(self._mainLightName)
    self._warnLights = ents.FindByName(self._warnLightName)
    self._warnLightBrushes = ents.FindByName(self._warnLightBrushName)

    ships.Add(self)

    self:SetHazardMode(false)
end

function ENT:Reset()
    for _, room in ipairs(self._roomlist) do
        room:Reset()
    end

    for _, door in ipairs(self._doors) do
        door:Reset()
    end
    
    self._nwdata.object:SetCoordinates(5 + math.random() * 0.2 - 0.1, 9 + math.random() * 0.2 - 0.1)
    self._nwdata.object:SetRotation(math.random() * 360)

    self:SetHazardMode(false)
end

function ENT:Think()
    if self:GetHazardMode() and CurTime() > self._hazardEnd then
        self:SetHazardMode(false)
    end
end

function ENT:SetHazardMode(value, duration)
    if value and CurTime() + duration > self._hazardEnd then
        self._hazardEnd = CurTime() + duration
    end

    if self._nwdata.hazardmode ~= value then
        self._nwdata.hazardmode = value
        self._nwdata:Update()

        for _, light in pairs(self._mainLights) do
            if value then
                light:Fire("turnoff", "", 0)
            else
                light:Fire("turnon", "", 0)
            end
        end

        for _, light in pairs(self._warnLights) do
            if value then
                light:Fire("turnon", "", 0)
            else
                light:Fire("turnoff", "", 0)
            end
        end

        for _, brush in pairs(self._warnLightBrushes) do
            if value then
                brush:Fire("SetTextureIndex", "1", 0)
            else
                brush:Fire("SetTextureIndex", "0", 0)
            end
        end
    end
end

function ENT:GetHazardMode()
    return self._nwdata.hazardmode
end

function ENT:GetBounds()
    return self._bounds
end

function _mt:GetOrigin()
    return self._nwdata.x, self._nwdata.y
end

function ENT:_SetBaseHealth(health, dontUpdate)
    self._nwdata.basehealth = health
    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetBaseHealth()
    return self._nwdata.basehealth
end

function ENT:_SetFullName(value, dontUpdate)
    self._nwdata.fullname = value
    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetFullName()
    return self._nwdata.fullname or "Unnamed"
end

function ENT:_SetUIColor(value, dontUpdate)
    if type(value) == "string" then
        local split = string.Split(value, " ")
        self._nwdata.uicolor = Color(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), 255)
    else
        self._nwdata.uicolor = value
    end

    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetUIColor()
    return self._nwdata.uicolor or Color(255, 255, 255, 255)
end

function ENT:AddRoom(room)
    local name = room:GetName()
    if not name or self:GetRoomByName(name) then return end

    self._roomdict[name] = room
    table.insert(self._roomlist, room)
    
    room:SetIndex(#self._roomlist)

    self._nwdata.roomnames[room:GetIndex()] = name
    self._nwdata:Update()
end

function ENT:GetRoomNames()
    return self._nwdata.roomnames
end

function ENT:GetRooms()
    return self._roomlist
end

function ENT:GetRoomByName(name)
    return self._roomdict[name]
end

function ENT:GetRoomByIndex(index)
    return self._roomlist[index]
end

function ENT:GetSystem(name)
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

function ENT:AddDoor(door)
    if not table.HasValue(self._doors, door) then
        table.insert(self._doors, door)
        door:SetIndex(#self._doors)

        self._nwdata.doornames[door:GetIndex()] = door:GetName()
        self._nwdata:Update()
    end
end

function ENT:GetDoorNames()
    return self._nwdata.doornames
end

function ENT:GetDoors()
    return self._doors
end

function ENT:GetDoorByIndex(index)
    return self._doors[index]
end

local ply_mt = FindMetaTable("Player")
function ply_mt:SetShip(ship)
    if self._ship == ship then return end
    if self._ship then
        self._ship:_RemovePlayer(self)
    end
    ship:_AddPlayer(self)
    self._ship = ship
    self:SetShipName(ship:GetName())
end

function ply_mt:GetShip()
    return self._ship
end

function ENT:_AddPlayer(ply)
    if not table.HasValue(self._players, ply) then
        table.insert(self._players, ply)
    end
end

function ENT:_RemovePlayer(ply)
    if table.HasValue(self._players, ply) then
        table.remove(self._players, table.KeyFromValue(self._players, ply))
    end
end

function ENT:GetPlayers()
    local i = #self._players
    while i > 0 do
        if not IsValid(self._players[i]) then
            table.remove(self._players, i)
        end
        i = i - 1
    end

    return self._players
end

function ENT:IsPointInside(x, y)
    return self:GetBounds():IsPointInside(x, y)
end
