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

GUI._innerRatio = 0.75

GUI._targ = 0
GUI._curr = 0

GUI.CurrentColour = Color(191, 191, 191, 255)
GUI.TargetColour = Color(127, 127, 127, 255)

function GUI:SetTargetValue(value)
    if value == self._targ then return end

    self._targ = value

    if CLIENT then self:_rebuildTargCircle() end
end

function GUI:GetTargetValue()
    return self._targ
end

function GUI:SetCurrentValue(value)
    if value == self._curr then return end

    self._curr = value

    if CLIENT then self:_rebuildCurrCircle() end
end

function GUI:GetCurrentValue()
    return self._curr
end

function GUI:SetInnerRatio(value)
    self._innerRatio = value

    if CLIENT then
        self:_rebuildTargCircle()
        self:_rebuildCurrCircle()
    end
end

function GUI:Initialize()
    self.Super[BASE].Initialize(self)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        layout.targ = self:GetTargetValue()
        layout.curr = self:GetCurrentValue()
        
        self.Super[BASE].UpdateLayout(self, layout)
    end
end

if CLIENT then
    GUI._targCircle = nil
    GUI._currCircle = nil

    function GUI:SetBounds(bounds)
        self.Super[BASE].SetBounds(self, bounds)

        self:_rebuildTargCircle()
        self:_rebuildCurrCircle()
    end

    function GUI:_buildCircle(value, width)
        local x, y = self:GetGlobalCentre()
        local outer = math.min(self:GetWidth(), self:GetHeight()) * 0.5
        local inner = outer * self._innerRatio
        local margin = (1.0 - width) * (outer - inner) * 0.5

        return CreateHollowCircle(x, y,
            inner + margin, outer - margin,
            -math.pi / 2, value * math.pi * 2)
    end

    function GUI:_rebuildTargCircle()
        self._targCircle = self:_buildCircle(self._targ, 1.0)
    end

    function GUI:_rebuildCurrCircle()
        self._currCircle = self:_buildCircle(self._curr, 0.5)
    end

    function GUI:Draw()
        draw.NoTexture()
        surface.SetDrawColor(self.TargetColour)
        for _, v in ipairs(self._targCircle) do
            surface.DrawPoly(v)
        end
        surface.SetDrawColor(self.CurrentColour)
        for _, v in ipairs(self._currCircle) do
            surface.DrawPoly(v)
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        self:SetTargetValue(layout.targ)
        self:SetCurrentValue(layout.curr)
    end
end
