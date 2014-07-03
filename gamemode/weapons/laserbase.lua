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

WPN.BaseName = BASE

WPN.Projectile = false

WPN.Arc = { 0, 0 }
WPN.Pulses = { 1, 1 }

function WPN:GetArc()
    return self:_FindValue(self.Arc)
end

function WPN:GetPulses()
    return self:_FindValue(self.Pulses)
end

if SERVER then
    function WPN:OnShoot(ship, target, rot)
        local sx, sy = ship:GetCoordinates()
        local tx, ty = target:GetCoordinates()
        local dx, dy = universe:GetDifference(sx, sy, tx, ty)
        if not rot then rot = math.atan2(dy, dx) / math.pi * 180 end

        weapon.LaunchMissile(ship, self, target, rot)
    end
end
