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

local BLACK = Color(0, 0, 0, 255)
local BASE = "base"

GUI.BaseName = BASE

GUI.CanClick = true

GUI.Text = "UNNAMED"
GUI.Color = Color(191, 191, 191, 255)
GUI.DisabledColor = Color(64, 64, 64, 255)

function GUI:OnClick(x, y, button)
    if SERVER and self:GetParent():GetCurrent() ~= self then
        self:GetParent():SetCurrent(self)
        self:GetScreen():UpdateLayout()
        return true
    end
    return false
end

if CLIENT then
    function GUI:Draw()
        surface.SetDrawColor(self.Color)
        if self:HasParent() and self:GetParent():GetCurrent() == self then
            surface.DrawRect(self:GetGlobalRect())
            surface.SetTextColor(BLACK)
        else
            if self.CanClick and self:IsCursorInside() then
                surface.DrawOutlinedRect(self:GetGlobalRect())
            end
            if self.CanClick then
                surface.SetTextColor(self.Color)
            else
                surface.SetTextColor(self.DisabledColor)
            end
        end

        local x, y = self:GetGlobalCentre()
        surface.SetFont("CTextSmall")
        surface.DrawCentredText(x, y, self.Text)

        self.Super[BASE].Draw(self)
    end
end
