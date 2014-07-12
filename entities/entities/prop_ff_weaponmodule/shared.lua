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

ENT.Base = "prop_ff_modulebase"

ENT._weapon = nil

if SERVER then
    concommand.Add("ff_spawn_weapon", function(ply, cmd, args)
        if not IsValid(ply) or not cvars.Bool("sv_cheats") then return end

        local trace = ply:GetEyeTraceNoCursor()

        local mdl = ents.Create("prop_ff_weaponmodule")
        mdl:SetWeapon(args[1] or weapon.GetRandomName(), args[2] and tonumber(args[2]) or nil)
        mdl:SetPos(trace.HitPos + trace.HitNormal * 8)
        mdl:Spawn()
    end, nil, "Spawn a weapon module", FCVAR_CHEAT)
end

function ENT:SetupDataTables()
    self.BaseClass.SetupDataTables(self)

    self:NetworkVar("Int", 2, "WeaponTier")

    self:NetworkVar("String", 1, "WeaponName")

    self:NetworkVar("Float", 0, "Charge")
end

function ENT:GetWeapon()
    return self._weapon
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
    function ENT:SetWeapon(name, tier)
        self:SetWeaponName(name)
        self._weapon = weapon.Create(name, tier)
        self:SetWeaponTier(self._weapon:GetTier())
    end

    function ENT:AddCharge(amount)
        if self:GetCharge() < self:GetMaxCharge() then
            local charge = math.min(self:GetCharge() + amount, self:GetMaxCharge())
            self:SetCharge(charge)
        end
    end

    function ENT:RemoveCharge(amount)
        if self:GetCharge() > 0 then
            local charge = math.max(self:GetCharge() - amount, 0)
            self:SetCharge(charge)
        end
    end

    function ENT:ClearCharge()
        self:SetCharge(0)
    end

    function ENT:RemoveFromSlot(ply)
        self.BaseClass.RemoveFromSlot(self, ply)

        self:ClearCharge()
    end

    function ENT:Initialize()
        self.BaseClass.Initialize(self)

        self:SetModuleType(5)

        if not self._weapon then self:SetWeapon("base") end
    end

    function ENT:CanInsertIntoSlot(slot)
        return slot:IsWeaponSlot()
    end
elseif CLIENT then
    function ENT:Think()
        if not IsValid(self) then return end
        
        if not self._weapon then
            local name = self:GetWeaponName()
            local tier = self:GetWeaponTier()
            if name and tier > 0 then self._weapon = weapon.Create(name, tier) end
        end
    end

    function ENT:Draw()
        self.BaseClass.Draw(self)

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
