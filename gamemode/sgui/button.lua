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

GUI.CanClick = true

GUI.Text = "CLICK ME"

GUI.Margin = 4

GUI.Color = Color(127, 127, 127, 255)
GUI.DisabledColor = Color(64, 64, 64, 255)
GUI.HighlightColor = Color(255, 255, 255, 32)
GUI.TextColor = Color(0, 0, 0, 255)

if CLIENT then
    function GUI:Draw()
        if self.CanClick then
            surface.SetDrawColor(self.Color)
        else
            surface.SetDrawColor(self.DisabledColor)
        end
        local x, y, w, h = self:GetGlobalRect()
        surface.DrawOutlinedRect(x, y, w, h)
        surface.DrawRect(x + self.Margin, y + self.Margin,
            w - self.Margin * 2, h - self.Margin * 2)

        if self.CanClick and self:IsCursorInside() then
            surface.SetDrawColor(self.HighlightColor)
            surface.DrawRect(x + self.Margin, y + self.Margin,
                w - self.Margin * 2, h - self.Margin * 2)
        end

        local cx, cy = self:GetGlobalCentre()
        surface.SetTextColor(self.TextColor)
        surface.SetFont("CTextSmall")
        surface.DrawCentredText(cx, cy, self.Text)

        self.Super[BASE].Draw(self)
    end
end
