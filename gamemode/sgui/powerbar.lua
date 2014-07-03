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

local BASE = "slider"

GUI.BaseName = BASE

GUI.CanClick = false
GUI.TextColor = Color(191, 191, 191, 255)

if CLIENT then
    function GUI:GetValueText(value)
        return FormatNum(self:GetSystem():GetPower(), 1, 2) .. "MW / " ..
            FormatNum(self:GetSystem():GetPowerNeeded(), 1, 2) .. "MW"
    end

    function GUI:DrawValueText(value)
        local text = self:GetValueText(value)
        surface.SetFont("CTextSmall")
        local x, y = self:GetGlobalCentre()
        local wid, hei = surface.GetTextSize(text)
        surface.SetTextColor(self.TextColor)
        surface.SetTextPos(x - wid / 2, y - hei / 2)
        surface.DrawText(text)
    end

    function GUI:Draw()
        if self:GetSystem():GetPowerNeeded() > 0 then
            self.Value = math.min(1, self:GetSystem():GetPower()
                / self:GetSystem():GetPowerNeeded())
        else
            self.Value = 0
        end

        self.Super[BASE].Draw(self)    
    end
end
