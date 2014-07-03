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

GUI.CanClick = true
GUI.Enabled = true

GUI.Label = nil

if CLIENT then
    local GLOW_STATES = {
        Color(172, 45, 51, 255),
        Color(172, 163, 48, 255),
        Color(51, 172, 45, 255)
    }

    local GLOW_DURATION = 1.0

    GUI.DisabledColor = Color(64, 64, 64, 255)
    GUI.EnabledColor = Color(191, 191, 191, 255)
    GUI.SelectedColor = Color(255, 255, 255, 255)
    GUI.TextColor = Color(0, 0, 0, 255)

    GUI._glowstart = 0
    GUI._glowstate = 0

    GUI._radius = 0

    function GUI:SetBounds(bounds)
        self.Super[BASE].SetBounds(self, bounds)
        self._radius = math.min(self:GetSize()) / 2
    end

    function GUI:IsPointInside(x, y)
        local cx, cy = self:GetCentre()
        local dx, dy = x - cx, y - cy
        return dx * dx + dy * dy <= self._radius * self._radius
    end

    function GUI:IsGlowing()
        return self._glowstate > 0
    end

    function GUI:StartGlow(state)
        self._glowstate = state
        self._glowstart = CurTime()
    end

    function GUI:Draw()
        local rad = self._radius
        local color = self.EnabledColor
        if self.Enabled and self.CanClick and self:IsCursorInside() then
            rad = math.cos(CurTime() * math.pi * 2) * self._radius * 0.06125 + self._radius
            color = self.SelectedColor
        elseif not self.Enabled then
            color = self.DisabledColor
        end

        if self._glowstate ~= 0 then
            local dt = 1 - (CurTime() - self._glowstart) / GLOW_DURATION

            if dt <= 0 then
                self._glowstate = 0
            else
                local state = GLOW_STATES[self._glowstate]
                local r = color.r + (state.r - color.r) * dt
                local g = color.g + (state.g - color.g) * dt
                local b = color.b + (state.b - color.b) * dt
                local a = color.a + (state.a - color.a) * dt
                color = Color(r, g, b, a)
                rad = rad + 8 * dt
            end
        end

        local x, y = self:GetGlobalCentre()

        surface.SetDrawColor(color)
        surface.DrawCircle(x, y, rad)

        surface.SetDrawColor(self.TextColor)
        surface.DrawCircle(x, y, rad - 2)

        surface.SetDrawColor(color)
        surface.DrawCircle(x, y, rad - 6)

        if self.Label then
            surface.SetTextColor(self.TextColor)
            surface.SetFont("CTextTiny")
            surface.DrawCentredText(x, y, self.Label)
        end

        self.Super[BASE].Draw(self)
    end
end
