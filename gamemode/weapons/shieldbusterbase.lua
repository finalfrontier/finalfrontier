-- Copyright (c) 2014 Alex Wlach (nightmarex91@gmail.com)
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

WPN.Projectile = true

WPN.Homing = true
WPN.Speed = { 1 / 2, 1 / 2 }
WPN.Lateral = { 1, 1 }
WPN.LifeTime = { 64, 64 }

function WPN:IsHoming()
    return self.Homing
end

function WPN:GetSpeed()
    return self:_FindValue(self.Speed)
end

function WPN:GetLateral()
    return self:_FindValue(self.Lateral)
end

function WPN:GetLifeTime()
    return self:_FindValue(self.LifeTime)
end

if SERVER then
    function WPN:OnShoot(ship, target, rot)
        weapon.LaunchMissile(ship, self, target, rot)
    end
end
