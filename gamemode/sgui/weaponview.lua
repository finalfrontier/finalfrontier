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

local BASE = "container"

GUI.BaseName = BASE

GUI.CanClick = true

GUI._slot = 0

GUI._icon = nil
GUI._nameLabel = nil
GUI._tierLabel = nil
GUI._powerBar = nil

function GUI:GetWeaponModule()
    return self:GetRoom():GetModule(self._slot)
end

function GUI:GetWeapon()
    local mdl = self:GetWeaponModule()
    if not mdl or not mdl.GetWeapon then return nil end
    return mdl:GetWeapon()
end

function GUI:SetWeaponSlot(value)
    self._slot = value
end

function GUI:Initialize()
    self.Super[BASE].Initialize(self)

    self._icon = sgui.Create(self, "image")

    self._nameLabel = sgui.Create(self, "label")
    self._nameLabel.AlignX = TEXT_ALIGN_CENTER
    self._nameLabel.AlignY = TEXT_ALIGN_CENTER

    self._tierLabel = sgui.Create(self, "label")
    self._tierLabel.AlignX = TEXT_ALIGN_CENTER
    self._tierLabel.AlignY = TEXT_ALIGN_CENTER

    self._powerBar = sgui.Create(self, "weaponpowerbar")
end

function GUI:SetBounds(bounds)
    self.Super[BASE].SetBounds(self, bounds)

    local margin = 8
    local iconSize = self:GetHeight() - margin * 2

    self._icon:SetOrigin(margin, margin)
    self._icon:SetSize(iconSize, iconSize)

    local textWidth = self:GetWidth() - iconSize - margin
    local textHeight = self:GetHeight() / 2

    self._nameLabel:SetOrigin(self._icon:GetRight(), 0)
    self._nameLabel:SetSize(textWidth * 2 / 3, textHeight)

    self._tierLabel:SetOrigin(self._nameLabel:GetRight(), 0)
    self._tierLabel:SetSize(textWidth / 3, textHeight)

    self._powerBar:SetOrigin(self._icon:GetRight() + 6, textHeight)
    self._powerBar:SetSize(textWidth - 12, textHeight - 6)
end

if CLIENT then
    function GUI:UpdateLayout(layout)
        local weapon = self:GetWeapon()
        if weapon then
            self._icon.Material = weapon.Icon
            self._icon.Color = weapon:GetColor()
            self._nameLabel.Color = Color(191, 191, 191, 255)
            self._nameLabel.Text = weapon:GetFullName()
            self._tierLabel.Text = weapon:GetTierName()
        else
            self._icon.Color = Color(0, 0, 0, 0)
            self._nameLabel.Text = ""
            self._tierLabel.Text = ""
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end

    function GUI:Draw()
        local r1 = 0
        if self:GetSystem():IsAutoShooting(self._slot) then r1 = 1 end
        local r0 = 1 - r1

        if self:GetWeaponModule() then
            if self:GetWeaponModule():CanShoot() then
                surface.SetDrawColor(Color(191 * r0 + 255 * r1, 191, 191, 255))
            else
                surface.SetDrawColor(Color(127 * r0 + 255 * r1, 127, 127, 255))
            end
        else
            surface.SetDrawColor(Color(32 * r0 + 64 * r1, 32, 32, 255))
        end
        
        surface.DrawOutlinedRect(self:GetGlobalRect())

        self.Super[BASE].Draw(self)

        if self.CanClick and self:IsCursorInside() and self:GetWeaponModule()
            and self:GetWeaponModule():CanShoot() then
            surface.SetDrawColor(Color(255, 255 * r0 + 127 * r1, 255 * r0 + 127 * r1, 8))
            surface.DrawRect(self:GetGlobalRect())
        elseif self:GetWeaponModule() then
            surface.SetDrawColor(Color(255, 255 * r0 + 127 * r1, 255 * r0 + 127 * r1, 4))
            surface.DrawRect(self:GetGlobalRect())
        end
    end
end
