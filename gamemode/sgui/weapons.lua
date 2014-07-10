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

local BASE = "page"

GUI.BaseName = BASE

GUI._grid = nil
GUI._powerBar = nil
GUI._targetLbl = nil
GUI._weapons = nil

function GUI:Enter()
    local gridSize = self:GetHeight() - 16
    local colWidth = self:GetWidth() - gridSize - 24
    self._grid = sgui.Create(self, "sectorgrid")
    self._grid:SetOrigin(8, 8)
    self._grid:SetSize(gridSize, gridSize)
    self._grid:SetCentreObject(nil)
    self._grid:SetScale(math.max(self._grid:GetMinScale(), self._grid:GetMinSensorScale()))

    self._powerBar = sgui.Create(self, "powerbar")
    self._powerBar:SetOrigin(self._grid:GetRight() + 8, 8)
    self._powerBar:SetSize(colWidth, 48)

    self._targetLbl = sgui.Create(self, "label")
    self._targetLbl:SetOrigin(self._grid:GetRight() + 8, self._powerBar:GetBottom() + 8)
    self._targetLbl:SetSize(colWidth, 48)
    self._targetLbl.AlignX = TEXT_ALIGN_CENTER
    self._targetLbl.AlignY = TEXT_ALIGN_CENTER
    self._targetLbl.Text = "No Target"

    local wpnHeight = 80

    self._weapons = {}
    for i = 1, 3 do
        local wpn = sgui.Create(self, "weaponview")
        local yof = 4 - i
        local slot = moduletype.WEAPON_1 + i - 1

        wpn:SetOrigin(self._grid:GetRight() + 8, self:GetHeight() - yof * (wpnHeight + 8))
        wpn:SetSize(colWidth, wpnHeight)
        wpn:SetWeaponSlot(slot)
        
        if SERVER then
            local oldOnSelectObject = self._grid.OnSelectObject
            self._grid.OnSelectObject = function(grid, obj, button)
                if self:GetSystem():CanTarget(obj) then
                    self:GetSystem():SetTarget(obj)
                else
                    self:GetSystem():SetTarget(nil)
                end

                return oldOnSelectObject(grid, obj, button)
            end

            self._grid.OnClickSelectedObject = function(grid, obj, button)
                if self:GetSystem():CanTarget(obj) and not self:GetSystem():HasTarget() then
                    self:GetSystem():SetTarget(obj)
                    return true
                else
                    return false
                end
            end

            wpn.OnClick = function(wpn, x, y, button)
                if button == MOUSE1 then
                    local mdl = wpn:GetWeaponModule()
                    if mdl and mdl:CanShoot() then
                        self:GetSystem():FireWeapon(slot)
                    end
                elseif button == MOUSE2 then
                    self:GetSystem():ToggleAutoShoot(slot)
                end
            end
        end
        
        self._weapons[i] = wpn
    end
end

if CLIENT then
    function GUI:Draw()
        local targ = self:GetSystem():GetTarget()
        if targ then
            self._targetLbl.Text = targ:GetDescription()
        else
            self._targetLbl.Text = "No Target"
        end

        self.Super[BASE].Draw(self)
    end
end
