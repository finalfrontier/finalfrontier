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

if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT._lastLerpTime = 0
ENT._currRotation = 0

objtype = {}
objtype.UNKNOWN = 0
objtype.SHIP = 1
objtype.MISSILE = 2
objtype.MODULE = 3

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ObjectName")
    self:NetworkVar("Int", 0, "ObjectType")
    self:NetworkVar("Float", 0, "TargetRotation")
    self:NetworkVar("Float", 1, "MaxAngularVel")
    self:NetworkVar("Entity", 0, "Module")
end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_junk/PopCan01a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:EnableCollisions(false)
            phys:EnableDrag(false)
            phys:EnableGravity(false)
            phys:EnableMotion(true)
            phys:Wake()
        end

        self:StartMotionController()

        self:SetTargetRotation(0)
        self:SetMaxAngularVel(45)
    else
        self._currRotation = self:GetTargetRotation()
    end

    self._lastLerpTime = CurTime()
end

if SERVER then
    function ENT:SetCoordinates(x, y)
        self:SetPos(universe:GetWorldPos(universe:WrapCoordinates(x, y)))
    end

    function ENT:SetRotation(angle)
        self._currRotation = angle
        self:SetTargetRotation(angle)
    end

    function ENT:SetVel(dx, dy)
        local orig = universe:GetWorldPos(0, 0)
        local next = universe:GetWorldPos(dx, dy)
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:SetVelocity(next - orig)
        end
    end

    function ENT:AssignModule(mdl)
        if mdl:GetClass() == "prop_ff_weaponmodule" then
            self:AssignWeaponModule(mdl:GetWeaponName(), mdl:GetWeaponTier())
        elseif mdl:GetClass() == "prop_ff_module" then 
            self:AssignRoomModule(mdl:GetModuleType(), mdl:GetGrid())
        end

        mdl:Remove()
    end

    function ENT:AssignWeaponModule(name, tier)
        self:SetObjectType(objtype.MODULE)

        self._module = {}
        self._module.type = moduletype.WEAPON_1
        self._module.name = name or weapon.GetRandomName()
        self._module.tier = tier or weapon.GetRandomTier(self._module.name)
    end

    function ENT:AssignRoomModule(type, grid)
        self:SetObjectType(objtype.MODULE)

        if grid then
            local old = grid
            grid = {}

            for x = 1, 4 do
                grid[x] = {}
                for y = 1, 4 do grid[x][y] = old[x][y] end
            end
        else
            grid = GenerateModuleGrid(0.5)
        end

        self._module = {}
        self._module.type = type
        self._module.grid = grid
    end

    function ENT:RetrieveModule()
        if not self._module then return nil end

        local mdl = nil

        if self._module.type == moduletype.WEAPON_1 then
            mdl = ents.Create("prop_ff_weaponmodule")
            mdl:SetWeapon(self._module.name, self._module.tier)
        else
            mdl = ents.Create("prop_ff_module")
            mdl:SetModuleType(self._module.type)
        end

        mdl:Spawn()

        if mdl:GetClass() == "prop_ff_module" then
            for x = 1, 4 do for y = 1, 4 do
                mdl:SetTile(x, y, self._module.grid[x][y])
            end end 
        end

        return mdl
    end
end

function ENT:GetRotation()
    local diff = FindAngleDifference(self._currRotation * math.pi / 180,
        self:GetTargetRotation() * math.pi / 180) / math.pi * 180

    local t = math.max(0, CurTime() - self._lastLerpTime)
    local vel = math.sign(diff) * math.min(math.abs(diff), t * self:GetMaxAngularVel())

    self._currRotation = self._currRotation + vel
    self._lastLerpTime = CurTime()

    return self._currRotation
end

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetRotationRadians()
    return self:GetRotation() * math.pi / 180.0
end

function ENT:GetVel()
    local ox, oy = universe:GetUniversePos(Vector(0, 0, 0))

    local nx, ny = 0, 0
    if SERVER then
        nx, ny = universe:GetUniversePos(self:GetPhysicsObject():GetVelocity())
    elseif CLIENT then
        nx, ny = universe:GetUniversePos(self:GetVelocity())
    end
    
    return nx - ox, ny - oy
end

function ENT:GetSpeed()
    local vx, vy = self:GetVel()
    return math.sqrt(vx * vx + vy * vy)
end

if SERVER then
    function ENT:Think()
        if not IsValid(self) then return end

        local x, y = self:GetCoordinates()
        local wx, wy = universe:WrapCoordinates(x, y)
        local phys = self:GetPhysicsObject()

        if math.abs(wx - x) >= 1 or math.abs(wy - y) >= 1 then
            local oldvel = phys:GetVelocity()
            self:SetCoordinates(wx, wy)
            phys:SetVelocity(oldvel)
        end

        if phys:IsAsleep() then
            phys:Wake()
        end
    end

    function ENT:PhysicsSimulate(phys, delta)
        return SIM_NOTHING
    end
elseif CLIENT then
    function ENT:GetDescription()
        if self:GetObjectType() == objtype.MODULE then
            return "Salvage"
        elseif self:GetObjectType() == objtype.SHIP then
            if LocalPlayer():GetShipName() == self:GetObjectName() then
                return "This Ship"
            else
                return "Enemy Ship"
            end
        elseif self:GetObjectType() == objtype.MISSILE then
            return "Missile"
        else
            return "Unknown"
        end
    end

    local function appendFlare(tbl, x, y, z, scale, r, g, b, pPeriod, pScale, pPhase)
        local flare = SpaceFlare(Vector(x / 8, y / 8, z / 8), scale, Color(r, g, b))
        flare:SetPulse(pPeriod, pScale, pPhase)

        table.insert(tbl, flare)
    end

    function ENT:GetSpaceFlare()
        if self:GetObjectType() == objtype.MODULE then
            local flare = SpaceFlare(0.125, Color(127, 255, 255, 255))
            flare:SetPulse(1, 0.25)
            return { flare }
        elseif self:GetObjectType() == objtype.MISSILE then
            local flare = SpaceFlare(0.125, Color(255, 0, 0, 255))
            flare:SetPulse(0.25, 0.25)
            return { flare }
        elseif self:GetObjectType() == objtype.SHIP then
            local flares = {}

            appendFlare(flares, 0, 1, 0, 0.125, 158, 204, 255, 1, 0.25, 0)
            appendFlare(flares, -0.25, -1, 0, 0.125, 158, 204, 255, 1, 0.25, 0.5)
            appendFlare(flares, 0.25, -1, 0, 0.125, 158, 204, 255, 1, 0.25, 0.5)

            return flares
        else
            local flare = SpaceFlare(0.125, Color(0, 255, 0, 255))
            flare:SetPulse(0.5, 0.25)
            return { flare }
        end
    end

    function ENT:Think()
        return
    end

    function ENT:Draw()
        return
    end
end
