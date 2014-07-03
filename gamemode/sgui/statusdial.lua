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

function GUI:Initialize()
    self.Super[BASE].Initialize(self)

    self:SetWidth(384)
    self:SetHeight(384)
end

if CLIENT then
    GUI._dialRadius = 192

    GUI._oldAtmo = 0
    GUI._oldShld = 0

    GUI._atmoCircle = nil
    GUI._shldCircle = nil
    GUI._innerCircle = nil

    function GUI:Draw()
        local x, y = self:GetGlobalCentre()
        local radius = math.min(self:GetWidth(), self:GetHeight()) * 0.45
        local room = self:GetScreen():GetRoom()

        local atmo, temp, shld, pwr = 0, 0, 0, 0
        if room then
            atmo = room:GetAtmosphere()
            temp = room:GetTemperature() / 600
            shld = room:GetShields()
            pwr = room:GetPowerRatio()
        end

        local scale = radius / 192

        local innerRad = radius / 2
        local midRad = radius * 3 / 4

        if not self._atmoCircle or self._dialRadius ~= radius or atmo ~= self._oldAtmo then
            self._atmoCircle = CreateHollowCircle(x, y, innerRad + 2 * scale, midRad - 2 * scale, -math.pi / 2, atmo * math.pi * 2)
            self._oldAtmo = atmo
        end

        if not self._shldCircle or self._dialRadius ~= radius or shld ~= self._oldShld then
            self._shldCircle = CreateHollowCircle(x, y, midRad + 2 * scale, radius - 2 * scale, -math.pi / 2, shld * math.pi * 2)
            self._oldShld = shld
        end

        if not self._innerCircle or self._dialRadius ~= radius then
            self._innerCircle = CreateCircle(x, y, innerRad - 2 * scale)
        end

        self._dialRadius = radius

        surface.SetDrawColor(Color(172, 45, 51, 255))
        surface.DrawPoly(self._innerCircle)

        surface.SetDrawColor(Color(0, 0, 0, 255))
        surface.DrawRect(x - radius / 2, y - radius / 2, radius, radius * (1 - temp))

        surface.SetDrawColor(Color(45, 51, 172, 255))
        for _, v in ipairs(self._shldCircle) do
            surface.DrawPoly(v)
        end
        surface.SetDrawColor(Color(51, 172, 45, 255))
        for _, v in ipairs(self._atmoCircle) do
            surface.DrawPoly(v)
        end

        surface.SetDrawColor(Color(255, 255, 255, 255))
        surface.DrawRect(x - 2 * scale, y - radius, 4 * scale, 286 * scale)

        for i = -4, 4 do
            if i ~= 0 then
                surface.DrawRect(x - 12 * scale, y + i * 16 * scale - 2 * scale, 24 * scale, 4 * scale)
            else
                surface.DrawRect(x - 24 * scale, y + i * 16 * scale - 2 * scale, 48 * scale, 4 * scale)
            end
        end

        local pwidth, pheight = self:GetWidth()/2 - radius, pwr * (self:GetHeight()/2)
        surface.SetDrawColor(Color(128, 128, 128, 255))
        surface.DrawRect(x - radius - pwidth, y - pheight, pwidth, pheight * 2)
        surface.DrawRect(x + radius, y - pheight, pwidth, pheight * 2)

        self.Super[BASE].Draw(self)
    end
end
