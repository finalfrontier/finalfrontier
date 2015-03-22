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

local TEMPERATURE_LOSS_RATE = 0.00000382
local AIR_LOSS_RATE = 1
local PLAYER_HEAT_RATE = 0.002
local DAMAGE_INTERVAL = 1.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT._ship = nil
ENT._screens = nil
ENT._system = nil
ENT._doorlist = nil
ENT._bounds = nil
ENT._polys = nil

ENT._details = nil
ENT._detailindices = nil

ENT._transpads = nil
ENT._transtargets = nil
ENT._dmgeffects = nil

ENT._moduleslots = nil
ENT._modules = nil

ENT._airvolume = 0
ENT._temperature = 0
ENT._shields = 0

ENT._lastupdate = 0
ENT._lastdamage = 0

ENT._players = nil

ENT._nwdata = nil

local function ShouldSync(a, b, delta)
    return math.abs(a - b) >= delta or (a ~= b and a * 100 == math.Round(a * 100))
end

function ENT:KeyValue(key, value)
    self._nwdata = self._nwdata or {}

    if key == "ship" then
        self:_SetShipName(tostring(value), true)
    elseif key == "system" then
        self:_SetSystemName(tostring(value), true)
    elseif key == "volume" then
        self:_SetVolume(tonumber(value), true)
        self:_SetSurfaceArea(math.sqrt(self:GetVolume()) * 6, true)
    end
end

function ENT:Initialize()
    self._screens = {}
    self._doorlist = {}
    self._bounds = Bounds()
    
    self._details = {}
    self._detailindices = {}

    self._dmgeffects = {}

    self._transpads = {}
    self._transtargets = {}

    self._moduleslots = {}
    self._modules = {}

    self._players = {}

    self._nwdata = NetworkTable(self:GetName(), self._nwdata)

    if not self._nwdata.corners then self._nwdata.corners = {} end
    if not self._nwdata.details then self._nwdata.details = {} end

    self._nwdata.modules = {}

    self._nwdata.temperature = 0
    self._nwdata.airvolume = 0
    self._nwdata.shields = 0
    self._nwdata.name = self:GetName()
    self._nwdata:Update()

    self:SetIndex(0)
end

function ENT:InitPostEntity()    
    self:_UpdateShip()

    if not self:GetShip() then return end

    self:Reset()
end

function ENT:Reset()
    self:_UpdateSystem()

    self:SetAirVolume(self:GetVolume())
    self:SetUnitTemperature(self:GetVolume() / 2)

    self:SetUnitShields(self:GetSurfaceArea())

    for type, slot in pairs(self._moduleslots) do
        self:_SpawnDefaultModule(type)
        slot:Reset()
    end

    self:_NextUpdate()
end

local DROWN_SOUNDS = {
    "npc/combine_soldier/pain1.wav",
    "npc/combine_soldier/pain2.wav",
    "npc/combine_soldier/pain3.wav"
}

function ENT:_NextUpdate()
    local curTime = CurTime()
    local dt = curTime - self._lastupdate
    self._lastupdate = curTime

    return dt
end

function ENT:Think()
    local dt = self:_NextUpdate()

    if self:HasSystem() then self:GetSystem():Think(dt) end

    local breachloss = 1
    local lifeModule = self:GetModule(moduletype.LIFE_SUPPORT)
    if lifeModule then
        breachloss = lifeModule:GetDamaged() / 16
    end

    breachloss = breachloss * 0.1 * dt
    
    self:SetUnitTemperature(self:GetUnitTemperature() *
        math.max(0, 1 - self:GetSurfaceArea() * TEMPERATURE_LOSS_RATE * dt
            - breachloss) +
        #self:GetPlayers() * PLAYER_HEAT_RATE * dt)

    self:SetAirVolume(self:GetAirVolume()
        - #self:GetPlayers() * AIR_LOSS_RATE * dt 
        - self:GetAirVolume() * breachloss)

    local bounds = self:GetBounds()
    local min = Vector(bounds.l, bounds.t, -65536)
    local max = Vector(bounds.r, bounds.b, 65536)

    for _, ent in pairs(ents.FindInBox(min, max)) do
        if IsValid(ent) then
            local pos = ent:GetPos()
            if ent:IsPlayer() and self:IsPointInside(pos.x, pos.y)
                and ent:GetRoom() ~= self then
                ent:SetRoom(self)
            end
        end
    end

    if CurTime() - self._lastdamage > DAMAGE_INTERVAL then
        local index = math.floor(self:GetAverageHealth() * #self._dmgeffects)
        for i, v in ipairs(self._dmgeffects) do
            if i > index then
                if not v:IsActive() then
                    v:SetActive(true)
                end
            else
                if v:IsActive() then 
                    v:SetActive(false)
                end
            end
        end

        local dmg = nil
        local sounds = nil

        if self:GetTemperature() > 350 then
            dmg = DamageInfo()
            dmg:SetDamageType(DMG_BURN)
            dmg:SetDamage(math.min(math.ceil((self:GetTemperature() - 350) / 25), 10))
        elseif self:GetAtmosphere() < 0.5 then
            dmg = DamageInfo()
            dmg:SetDamageType(DMG_ACID)
            dmg:SetDamage(math.min(math.ceil((0.5 - self:GetAtmosphere()) * 10), 10))
            sounds = DROWN_SOUNDS
        end

        if dmg then
            dmg:SetAttacker(self)
            dmg:SetInflictor(self)
            for _, ply in pairs(self._players) do
                if ply and ply:IsValid() and ply:Alive() then
                    ply:TakeDamageInfo(dmg)
                    if sounds then
                        ply:EmitSound(table.Random(sounds), SNDLVL_IDLE, 100)
                    end
                end
            end
        end
        self._lastdamage = CurTime()
    end
end

function ENT:SetIndex(index)
    self._nwdata.index = index
    self._nwdata:Update()
end

function ENT:GetIndex()
    return self._nwdata.index
end

function ENT:_SetShipName(name, dontUpdate)
    self._nwdata.shipname = name
    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetShipName()
    return self._nwdata.shipname
end

function ENT:_UpdateShip()
    local name = self:GetShipName()
    if name then
        self._ship = ships.GetByName(name)
        if self._ship then
            self._ship:AddRoom(self)
        end
    else
        Error("Room at " .. tostring(self:GetPos()) .. " (" .. self:GetName()
            .. ") has no ship!\n")
    end
end

function ENT:GetShip()
    return self._ship
end

function ENT:_SetSystemName(name, dontUpdate)
    self._nwdata.systemname = name
    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetSystemName()
    return self._nwdata.systemname
end

function ENT:_UpdateSystem()
    local name = self:GetSystemName()
    if name then
        self._system = sys.Create(name, self)
    end
end

function ENT:HasSystem()
    return self._system ~= nil
end

function ENT:GetSystem()
    return self._system
end

function ENT:_SetVolume(value, dontUpdate)
    self._nwdata.volume = value
    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetVolume()
    return self._nwdata.volume or 0
end

function ENT:_SetSurfaceArea(value, dontUpdate)
    self._nwdata.surfacearea = value
    if not dontUpdate then self._nwdata:Update() end
end

function ENT:GetSurfaceArea()
    return self._nwdata.surfacearea or 0
end

function ENT:GetBounds()
    return self._bounds
end

function ENT:GetPolygons()
    if not self._polys then
        self._polys = FindConvexPolygons(self._nwdata.corners)
    end
    return self._polys
end

function ENT:AddCorner(index, x, y)
    if not self._nwdata.corners then self._nwdata.corners = {} end

    self._nwdata.corners[index] = { x = x, y = y }
    self:GetBounds():AddPoint(x, y)
    self:GetShip():GetBounds():AddPoint(x, y)
    self._nwdata:Update()

    self._polys = nil
end

function ENT:GetCorners()
    return self._nwdata.corners
end

function ENT:_GetDetailIndex(name)
    if not self._detailindices[name] then
        local index = table.Count(self._detailindices) + 1
        self._detailindices[name] = index
        self._details[index] = { x = 0, y = 0 }
        return index
    end

    return self._detailindices[name]
end

function ENT:AddDetail(name, x, y, nextnames)
    if not self._nwdata.details then self._nwdata.details = {} end

    local index = self:_GetDetailIndex(name)
    self._details[index].x = x
    self._details[index].y = y

    for _, v in pairs(nextnames) do
        local otherIndex = self:_GetDetailIndex(v)
        table.insert(self._nwdata.details, {
            a = self._details[index], b = self._details[otherIndex]
        } )
    end

    self._nwdata:Update()
end

function ENT:GetDetails()
    return self._nwdata.details
end

function ENT:AddDamageEffect(dmgeffect)
    local index = math.floor(math.random() * (#self._dmgeffects + 1)) + 1
    table.insert(self._dmgeffects, index, dmgeffect)
end

function ENT:GetDamageEffects()
    return self._dmgeffects
end

function ENT:GetAverageHealth()
    local total = 0
    for i = 0, 2 do
        total = total + self:GetModuleIntegrity(i)
    end
    if #self._moduleslots == 0 then return 1 end
    return total / math.min(3, table.Count(self._moduleslots))
end

function ENT:AddTransporterTarget(pos, isTransPad)
    if isTransPad then
        table.insert(self._transpads, pos)
    else
        table.insert(self._transtargets, pos)
    end
end

function ENT:GetTransporterPads()
    return self._transpads
end

-- Stolen from TTT
local function ShouldCollide(ent)
    if ent:IsWorld() or string.StartWith(ent:GetClass(), "info_ff_") then
        return false
    end
    local g = ent:GetCollisionGroup()
    return (g ~= COLLISION_GROUP_WEAPON and
        g ~= COLLISION_GROUP_DEBRIS and
        g ~= COLLISION_GROUP_DEBRIS_TRIGGER and
        g ~= COLLISION_GROUP_INTERACTIVE_DEBRIS)
end

function ENT:GetAvailableTransporterTargets()
    local available = {}
    for _, set in pairs({self._transpads, self._transtargets}) do
        for _, pos in pairs(set) do
            local obstructed = false
            for _, ent in pairs(ents.FindInBox(pos - Vector(48, 48, 0),
                pos + Vector(48, 48, 96))) do
                if ShouldCollide(ent) then
                    obstructed = true
                    break
                end
            end
            if not obstructed then
                table.insert(available, pos)
            end
        end
    end
    return available
end

function ENT:GetTransporterTargets()
    return self._transtargets
end

function ENT:GetTransporterTarget()
    return table.Random(self:GetAvailableTransporterTargets()) or nil
end

function ENT:AddModuleSlot(slot)
    local type = slot:GetModuleType()

    self._moduleslots[type] = slot
    self:_SpawnDefaultModule(type)
end

function ENT:_SpawnDefaultModule(type)
    local pos = self._moduleslots[type]:GetPos()
    local cur = self:GetModule(type)

    if cur ~= nil then
        self:RemoveModule(cur)
        cur:Remove()
    end

    if type < moduletype.REPAIR_1 then
        local mdl = ents.Create("prop_ff_module")
        mdl:SetModuleType(type)
        mdl:SetDefaultGrid(self:GetShip())
        mdl:Spawn()
        mdl:InsertIntoSlot(self, type, pos)
    end
end

function ENT:GetModuleScore(type)
    local mdl = self:GetModule(type)
    if not mdl then return 0 end
    return mdl:GetScore()
end

function ENT:GetModuleIntegrity(type)
    local mdl = self:GetModule(type)
    if not mdl then return 1 end
    return 1 - (mdl:GetDamaged() / 16)
end

function ENT:GetModule(type)
    return self._modules[type]
end

function ENT:GetSlot(module)
    for i, v in pairs(self._modules) do
        if v == module then return i end
    end
    return nil
end

function ENT:SetModule(type, module)
    self._modules[type] = module
    self._nwdata.modules[type] = module:EntIndex()
    self._nwdata:Update()
end

function ENT:RemoveModule(module)
    for i, v in pairs(self._modules) do
        if v == module then
            if (i == moduletype.REPAIR_1 or i == moduletype.REPAIR_2)
                and self:GetSystem():IsPerformingAction() then
                return false
            end
            self._modules[i] = nil
            self._nwdata.modules[i] = nil
            self._nwdata:Update()
            return true
        end
    end
    return false
end

function ENT:AddDoor(door)
    if table.HasValue(self._doorlist, door) then return end

    table.insert(self._doorlist, door)
end

function ENT:GetDoors()
    return self._doorlist
end

function ENT:AddScreen(screen)
    table.insert(self._screens, screen)
end

function ENT:GetScreens()
    return self._screens
end

function ENT:SetUnitTemperature(temp)
    self._temperature = math.Clamp(temp, 0, self:GetVolume())

    if ShouldSync(self._temperature, self._nwdata.temperature, self:GetVolume() / 100) then
        self._nwdata.temperature = self._temperature
        self._nwdata:Update()
    end
end

function ENT:GetUnitTemperature()
    return self._temperature
end

function ENT:GetTemperature()
    return self:GetUnitTemperature() * 600 / self:GetVolume()
end

function ENT:SetAirVolume(volume)
    self._airvolume = math.Clamp(volume, 0, self:GetVolume())

    if ShouldSync(self._airvolume, self._nwdata.airvolume, self:GetVolume() / 100) then
        self._nwdata.airvolume = self._airvolume
        self._nwdata:Update()
    end
end

function ENT:GetAirVolume()
    return self._airvolume or 0
end

function ENT:SetAtmosphere(atmosphere)
    self:SetAirVolume(self:GetVolume() * atmosphere)
end

function ENT:GetAtmosphere()
    return self:GetAirVolume() / self:GetVolume()
end

function ENT:SetUnitShields(shields)
    self._shields = math.Clamp(shields, 0, self:GetMaximumUnitShields())

    if ShouldSync(self._shields, self._nwdata.shields, 1 / 100) then
        self._nwdata.shields = self._shields
        self._nwdata:Update()
    end
end

function ENT:GetUnitShields()
    return self._shields or 0
end

function ENT:GetMaximumUnitShields()
    local shieldMod = self:GetModule(moduletype.SHIELDS)
    if not shieldMod then return 0 end
    return self:GetSurfaceArea() * (1 - shieldMod:GetDamaged() / 16)
end

function ENT:GetShields()
    return self:GetUnitShields() / self:GetSurfaceArea()
end

function ENT:GetMaximumShields()
    return self:GetMaximumUnitShields() / self:GetSurfaceArea()
end

function ENT:TransmitTemperature(room, delta)
    if delta < 0 then room:TransmitTemperature(self, delta) return end

    delta = math.min(delta, self:GetUnitTemperature())
    
    self:SetUnitTemperature(self:GetUnitTemperature() - delta)
    room:SetUnitTemperature(room:GetUnitTemperature() + delta)
end

function ENT:TransmitAir(room, delta)
    if delta < 0 then room:TransmitAir(self, delta) return end

    delta = math.min(delta, self:GetAirVolume())
    
    self:SetAirVolume(self:GetAirVolume() - delta)
    room:SetAirVolume(room:GetAirVolume() + delta)
end

function ENT:GetPermissionsName()
    return self:GetShipName() .. "_" .. self:GetIndex()
end

function ENT:HasPlayerWithSecurityPermission()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:HasPermission(self, permission.SECURITY, true) then
            return true
        end
    end

    return false
end

local ply_mt = FindMetaTable("Player")
function ply_mt:SetPermission(room, perm)
    self._permissions[room:GetPermissionsName()] = perm
    self._permissions:Update()
end

function ply_mt:SetRoom(room)
    if self._room == room then return end
    if self._room then
        self._room:_RemovePlayer(self)
    end
    room:_AddPlayer(self)
    self._room = room
    self:SetRoomIndex(room:GetIndex())
end

function ply_mt:GetRoom()
    return self._room
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
    return self._players
end

function ENT:GetEntities()
    local bounds = self:GetBounds()
    local min = Vector(bounds.l, bounds.t, -65536)
    local max = Vector(bounds.r, bounds.b, 65536)

    local matches = {}

    for _, ent in pairs(ents.FindInBox(min, max)) do
        local pos = ent:GetPos()
        if ent:GetClass() ~= "info_ff_object" and self:IsPointInside(pos.x, pos.y) then
            table.insert(matches, ent)
        end
    end

    return matches
end

function ENT:IsPointInside(x, y)
    return self:GetBounds():IsPointInside(x, y)
        and IsPointInsidePolyGroup(self:GetPolygons(), x, y)
end
