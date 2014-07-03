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

GUI.Player = nil

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.player = self.Player
    end
end

if CLIENT then
    function GUI:Draw()
        local x, y = self:GetPos()

        surface.SetDrawColor(Color(255, 0, 0, 255))
        surface.DrawCircle(x, y, 64)

        surface.SetTextColor(Color(255, 255, 255, 255))
        surface.SetFont("CTextLarge")

        if self.Player then
            surface.DrawCentredText(x, y, self.Player:Nick())
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        self.Player = layout.player
    end
end
