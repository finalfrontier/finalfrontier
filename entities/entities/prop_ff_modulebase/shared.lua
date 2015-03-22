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

moduletype = {}
moduletype.LIFE_SUPPORT = 0
moduletype.SHIELDS = 1
moduletype.SYSTEM_POWER = 2
moduletype.REPAIR_1 = 3
moduletype.REPAIR_2 = 4
moduletype.WEAPON_1 = 5
moduletype.WEAPON_2 = 6
moduletype.WEAPON_3 = 7

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "RoomIndex")
    self:NetworkVar("Int", 1, "ModuleType")

    self:NetworkVar("String", 0, "ShipName")
end

function ENT:IsInSlot()
    return self:GetRoomIndex() > -1
end

function ENT:GetSlotType()
    if not self:IsInSlot() then return nil end
    return self:GetRoom():GetSlot(self)
end

function ENT:GetRoom()
    if not self:IsInSlot() then return nil end
    local ship = ships.GetByName(self:GetShipName())
    return ship:GetRoomByIndex(self:GetRoomIndex())
end

if SERVER then
    function ENT:Initialize()
        self:SetRoomIndex(-1)

        self:SetUseType(SIMPLE_USE)

        self:SetModel("models/props_c17/consolebox01a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end

    function ENT:InsertIntoSlot(room, type, slot)
        if not self:IsInSlot() and not self:IsPlayerHolding() and not room:GetModule(type) then
            self:SetShipName(room:GetShipName())
            self:SetRoomIndex(room:GetIndex())

            room:SetModule(type, self)

            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end

            self:SetPos(slot - Vector(0, 0, 4))

            local yaw = self:GetAngles().y
            yaw = math.Round(yaw / 90) * 90

            self:SetAngles(Angle(0, yaw, 0))
        end
    end

    function ENT:RemoveFromSlot(ply)
        if self:IsInSlot() and self:GetRoom():RemoveModule(self) then
            self:SetPos(self:GetPos() + Vector(0, 0, 12))

            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(true)
                phys:Wake()

                local vel = Vector(0, 0, 128)
                if IsValid(ply) then
                    local diff = self:GetPos() - ply:GetPos()
                    vel.x = vel.x + diff.x
                    vel.y = vel.y + diff.y
                end

                phys:SetVelocity(vel)
            end

            self:SetShipName("")
            self:SetRoomIndex(-1)
        end
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        if self:IsInSlot() then
            self:RemoveFromSlot(ply)
        end

        if not self:IsPlayerHolding() then
            self:SetAngles(Angle(0, self:GetAngles().y, 0))
            ply:PickupObject(self)
        end
    end

    function ENT:CanInsertIntoSlot(type)
        return false
    end

    function ENT:Think()
        if not IsValid(self) then return end

        if not self:IsInSlot() then
            local min, max = self:GetCollisionBounds()
            min = min + self:GetPos() - Vector(0, 0, 8)
            max = max + self:GetPos()
            local near = ents.FindInBox(min, max)
            for _, v in pairs(near) do
                if IsValid(v) and v:GetClass() == "info_ff_moduleslot" then
                    if self:CanInsertIntoSlot(v) then
                        self:InsertIntoSlot(v:GetRoom(), v:GetModuleType(), v:GetPos())
                        break
                    end
                end
            end
        end
    end

    function ENT:OnRemove()
        if self:IsInSlot() then self:RemoveFromSlot(nil) end
    end
elseif CLIENT then
    function ENT:Initialize()
        self:SetCustomCollisionCheck(true)
    end
end
