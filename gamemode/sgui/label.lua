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

GUI.CanClick = false

GUI.Text = "Hello World!"
GUI.Font = "CTextSmall"
GUI.Color = Color(191, 191, 191, 255)

GUI.AlignX = TEXT_ALIGN_LEFT
GUI.AlignY = TEXT_ALIGN_TOP

if CLIENT then
    function GUI:Draw()
        surface.SetTextColor(self.Color)
        surface.SetFont(self.Font)

        local w, h = surface.GetTextSize(self.Text)
        local x, y = self:GetGlobalOrigin()

        if self.AlignX == TEXT_ALIGN_CENTER then
            x = x + (self:GetWidth() - w) / 2
        elseif self.AlignX == TEXT_ALIGN_RIGHT then
            x = x + self:GetWidth() - w
        end

        if self.AlignY == TEXT_ALIGN_CENTER then
            y = y + (self:GetHeight() - h) / 2
        elseif self.AlignY == TEXT_ALIGN_BOTTOM then
            y = y + self:GetHeight() - h
        end

        surface.SetTextPos(x, y)
        surface.DrawText(self.Text)

        self.Super[BASE].Draw(self)
    end
end
