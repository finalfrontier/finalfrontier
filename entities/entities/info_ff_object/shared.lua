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
objtype.unknown = 0
objtype.ship = 1
objtype.missile = 2

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "TargetRotation")
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

    function ENT:SetMaxAngularVel(vel)
        self:SetNWFloat("maxangvel", vel)
    end

    function ENT:SetObjectType(type)
        self:SetNWInt("objtype", type)
    end

    function ENT:SetObjectName(name)
        self:SetNWString("objname", name)
    end
end

function ENT:GetMaxAngularVel()
    return self:GetNWFloat("maxangvel", 0)
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
    local nx, ny = universe:GetUniversePos(self:GetVelocity())
    return nx - ox, ny - oy
end

function ENT:GetSpeed()
    local vx, vy = self:GetVel()
    return math.sqrt(vx * vx + vy * vy)
end

function ENT:GetObjectType()
    return self:GetNWInt("objtype", objtype.unknown)
end

function ENT:GetObjectName()
    return self:GetNWString("objname", nil)
end

if SERVER then
    function ENT:Think()
        local x, y = self:GetCoordinates()
        local wx, wy = universe:WrapCoordinates(x, y)
        if math.abs(wx - x) >= 1 or math.abs(wy - y) >= 1 then
            self:SetCoordinates(wx, wy)
        end

        local phys = self:GetPhysicsObject()
        if phys:IsValid() and phys:IsAsleep() then
            phys:Wake()
        end
    end

    function ENT:PhysicsSimulate(phys, delta)
        return SIM_NOTHING
    end
elseif CLIENT then
    function ENT:Think()
        return
    end

    function ENT:Draw()
        return
    end
end
