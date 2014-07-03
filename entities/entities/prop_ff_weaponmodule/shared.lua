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

ENT._weapon = nil

function ENT:GetModuleType()
    return 5
end

function ENT:IsInSlot()
    return self:GetNWInt("room", -1) > -1
end

function ENT:GetSlotType()
    if not self:IsInSlot() then return nil end
    return self:GetRoom():GetSlot(self)
end

function ENT:GetRoom()
    if not self:IsInSlot() then return nil end
    local ship = ships.GetByName(self:GetNWString("ship"))
    return ship:GetRoomByIndex(self:GetNWInt("room"))
end

function ENT:GetWeaponName()
    return self:GetNWString("weapon")
end

function ENT:GetWeaponTier()
    return self:GetNWInt("tier", 0)
end

function ENT:GetWeapon()
    return self._weapon
end

function ENT:GetCharge()
    return self:GetNWFloat("charge", 0)
end

function ENT:GetMaxCharge()
    return self._weapon:GetMaxCharge()
end

function ENT:IsFullyCharged()
    return self._weapon:GetMaxCharge() > 0 and self._weapon:GetMaxCharge() <= self:GetCharge()
end

function ENT:CanShoot()
    return self:GetCharge() >= self._weapon:GetShotCharge()
end

if SERVER then
    function ENT:SetWeapon(name)
        self:SetNWString("weapon", name)
        self._weapon = weapon.Create(name)
        self:SetNWInt("tier", self._weapon:GetTier())
    end

    function ENT:AddCharge(amount)
        if self:GetCharge() < self:GetMaxCharge() then
            local charge = math.min(self:GetCharge() + amount, self:GetMaxCharge())
            self:SetNWFloat("charge", charge)
        end
    end

    function ENT:RemoveCharge(amount)
        if self:GetCharge() > 0 then
            local charge = math.max(self:GetCharge() - amount, 0)
            self:SetNWFloat("charge", charge)
        end
    end

    function ENT:ClearCharge()
        self:SetNWFloat("charge", 0)
    end

    function ENT:Initialize()
        self:SetUseType(SIMPLE_USE)

        self:SetModel("models/props_c17/consolebox01a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        if not self._weapon then self:SetWeapon("base") end
    end

    function ENT:InsertIntoSlot(room, type, slot)
        if not self:IsInSlot() and not self:IsPlayerHolding() and not room:GetModule(type) then
            self:SetNWString("ship", room:GetShipName())
            self:SetNWInt("room", room:GetIndex())

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

            self:SetNWString("ship", "")
            self:SetNWInt("room", -1)

            self:ClearCharge()
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

    function ENT:Think()
        if not self:IsInSlot() then
            if self:GetCharge() > 0 then self:SetCharge(0) end

            local min, max = self:GetCollisionBounds()
            min = min + self:GetPos() - Vector(0, 0, 8)
            max = max + self:GetPos()
            local near = ents.FindInBox(min, max)
            for _, v in pairs(near) do
                if v:GetClass() == "info_ff_moduleslot" then
                    local type = v:GetModuleType()
                    if v:IsWeaponSlot() then
                        self:InsertIntoSlot(v:GetRoom(), type, v:GetPos())
                        return
                    end
                end
            end
        end
    end
elseif CLIENT then
    function ENT:Think()
        if not self._weapon then
            local name = self:GetWeaponName()
            local tier = self:GetWeaponTier()
            if name and tier > 0 then self._weapon = weapon.Create(name, tier) end
        end
    end

    function ENT:Draw()
        self:DrawModel()

        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), -90)
        
        draw.NoTexture()
        
        local scale = 1 / 16
        local size = 24 / scale
        cam.Start3D2D(self:GetPos() + ang:Up() * 11, ang, scale)

            surface.SetDrawColor(Color(0, 0, 0, 255))
            surface.DrawRect(-size / 2, -size / 2, size, size)

            if self._weapon then
                surface.SetTextColor(Color(191, 191, 191, 255))
                surface.SetFont("CTextLarge")

                local text = self._weapon:GetFullName()

                local w, h = surface.GetTextSize(text)

                if w > size - 32 then
                    surface.SetFont("CTextMedium")
                    w, h = surface.GetTextSize(text)
                end

                local x = -size / 2 + (size - w) / 2
                local y = -size / 2 + (size / 4 - h) / 2

                surface.SetTextPos(x, y)
                surface.DrawText(text)

                surface.SetDrawColor(self._weapon:GetColor())
                surface.SetMaterial(self._weapon.Icon)
                surface.DrawTexturedRect(-size / 2 + 8, -size / 4 - 8, size / 2 - 16, size / 2 - 16)
                draw.NoTexture()

                surface.SetFont("CTextLarge")
                
                text = self._weapon:GetTierName()

                w, h = surface.GetTextSize(text)
                x = (size / 2 - w) / 2
                y = -size / 4 - 16 + (size / 2 - h) / 2

                surface.SetTextPos(x, y)
                surface.DrawText(text)

                surface.SetDrawColor(Color(191, 191, 191, 255))
                surface.DrawOutlinedRect(-size / 2 + 8, size / 4 + 8, size - 16, size / 4 - 16)

                if self:GetCharge() == 0 then
                    surface.SetTextColor(Color(172, 45, 51, 255))
                    surface.SetFont("CTextSmall")

                    text = "NO CHARGE"

                    w, h = surface.GetTextSize(text)
                    x = -size / 2 + (size - w) / 2
                    y = size / 4 + (size / 4 - h) / 2

                    surface.SetTextPos(x, y)
                    surface.DrawText(text)
                else
                    local totbars = math.ceil(self._weapon:GetMaxCharge())
                    local barspacing = 4
                    local barsize = (size - 32 + barspacing) / totbars

                    local bars = (self:GetCharge() / self._weapon:GetMaxCharge()) * totbars

                    if not self:CanShoot() then
                        surface.SetDrawColor(Color(191, 191, 191, 255))
                    end

                    for i = 0, bars - 1 do
                        if self:CanShoot() then
                            surface.SetDrawColor(LerpColour(Color(191, 191, 191, 255), Color(255, 255, 159, 255), Pulse(0.5, -i / totbars / 4)))
                        end

                        surface.DrawRect(-size / 2 + 16 + i * barsize, size / 4 + 16, barsize - barspacing, size / 4 - 32)
                    end
                end
            end
        cam.End3D2D()
    end
end
