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

local BASE = "missilebase"

WPN.BaseName = BASE
WPN.CanSpawn = true

WPN.MaxTier = 5

WPN.MaxPower = { 2, 4 }
WPN.MaxCharge = { 12, 20 }
WPN.ShotCharge = { 12, 16 }

WPN.Homing = true
WPN.Speed = { 1 / 6, 1 / 6 }
WPN.Lateral = { 1, 1 }
WPN.LifeTime = { 16, 24 }

WPN.BaseDamage = { 20, 50 }
WPN.PierceRatio = { 0, 0 }
WPN.ShieldMult = { 4, 4 }

if CLIENT then
    WPN.FullName = "Vesta Missile"
    WPN.Color = Color(239, 255, 255, 255)
end
