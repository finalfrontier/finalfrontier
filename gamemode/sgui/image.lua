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

if CLIENT then
    GUI.Color = Color(255, 255, 255, 255)
    GUI.Material = WHITE

    function GUI:Draw()
        if self.Material then
            surface.SetDrawColor(self.Color)
            surface.SetMaterial(self.Material)
            surface.DrawTexturedRect(
                self:GetGlobalLeft(),
                self:GetGlobalTop(),
                self:GetWidth(),
                self:GetHeight()
            )
            draw.NoTexture()
        end
        
        self.Super[BASE].Draw(self)
    end
end
