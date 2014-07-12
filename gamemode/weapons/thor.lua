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

local BASE = "shieldbusterbase"

WPN.BaseName = BASE
WPN.CanSpawn = true

WPN.MaxTier = 10

WPN.MaxPower = { 0.5, 4 }
WPN.MaxCharge = { 8, 16 }
WPN.ShotCharge = { 2, 4 }

WPN.Homing = true
WPN.Speed = { 1 / 6, 1 / 1 }
WPN.Lateral = { 0.1, 1 }
WPN.LifeTime = { 64, 128 }

WPN.BaseDamage = { 1, 10 }
WPN.PierceRatio = { 0, 0 }

WPN.PersonnelMult = { 0, 0 }

WPN.LifeSupportModuleMult = { 0, 0 }
WPN.ShieldModuleMult = { 0, 0 }
WPN.ShieldMult = { 8, 32 }

if CLIENT then
    WPN.FullName = "Project Thor"
    WPN.Color = Color(231, 76, 60, 255)
end
