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

local BASE = "base"

GUI.BaseName = BASE

GUI._slot = -1

function GUI:SetSlot(type)
    self._slot = type
end

function GUI:GetSlot()
    return self._slot
end

function GUI:GetModule()
    return self:GetRoom():GetModule(self._slot)
end

function GUI:GetGrid()
    local mdl = self:GetModule()
    if not mdl then return nil end
    return mdl:GetGrid()
end

if CLIENT then
    GUI._progX = 0
    GUI._progY = 0

    function GUI:IsGridLoaded()
        local mdl = self:GetModule()
        if not mdl then return false end
        return mdl:IsGridLoaded()
    end

    function GUI:Draw()
        local xs, ys = self:GetSize()
        xs, ys = xs / 40, ys / 40

        local cx, cy = self:GetGlobalCentre()

        if self:IsGridLoaded() then
            local mdl = self:GetModule()
            local grid = self:GetGrid()

            for i = 1, 4 do
                local x = (i - 2.5) * 10
                for j = 1, 4 do
                    local y = (j - 2.5) * 10
                    local val = grid[i][j]
                    if val == 0 then
                        surface.SetDrawColor(Color(51, 172, 45, 255))
                    elseif val == 1 then
                        surface.SetDrawColor(Color(45, 51, 172, 255))
                    else
                        surface.SetDrawColor(Color(172, 45, 51, Pulse(1) * 63 + 32))
                    end
                    surface.DrawRect(cx + (x - 4) * xs, cy + (y - 4) * ys, 8 * xs, 8 * ys)
                end
            end

            surface.SetDrawColor(Color(255, 255, 255, 16))
            surface.SetMaterial(modulematerials[mdl:GetModuleType() + 1])
            surface.DrawTexturedRect(cx - 20 * xs, cy - 20 * ys, 40 * xs, 40 * ys)

            if self:GetSystem():IsPerformingAction() then
                local progress = math.min(15, math.floor(self:GetSystem():GetActionProgress()))
                if progress == 0 then
                    self._progX = 1
                    self._progY = 1
                else
                    local y = math.floor(progress / 4)
                    local x = progress - y * 4

                    self._progX = self._progX + (x + 1 - self._progX) * 0.1
                    self._progY = self._progY + (y + 1 - self._progY) * 0.1
                end

                local x = (self._progX - 2.5) * 10
                local y = (self._progY - 2.5) * 10
                surface.SetDrawColor(Color(255, 255, 255, Pulse(1) * 64 + 127))
                surface.DrawOutlinedRect(cx + (x - 5) * xs, cy + (y - 5) * ys, 10 * xs, 10 * ys)                
            end
        else
            surface.SetDrawColor(Color(255, 255, 255, 4))
            surface.DrawRect(cx - 20 * xs, cy - 20 * ys, 40 * xs, 40 * ys)

            surface.SetDrawColor(Color(255, 255, 255, 16))
            surface.DrawOutlinedRect(cx - 20 * xs, cy - 20 * ys, 40 * xs, 40 * ys)

            surface.SetDrawColor(Color(255, 255, 255, 16))
            surface.SetMaterial(modulematerials[4])
            surface.DrawTexturedRect(cx - 10 * xs, cy - 10 * ys, 20 * xs, 20 * ys)
        end
        
        self.Super[BASE].Draw(self)
    end
end
