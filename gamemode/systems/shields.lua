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

SYS.FullName = "Shield Control"
SYS.SGUIName = "shields"

SYS.Powered = true

if SERVER then
    resource.AddFile("materials/systems/shields.png")

    local SHIELD_RECHARGE_RATE = 2.5
    local SHIELD_POWER_PER_M2 = 0.004
    
    SYS._distrib = nil
    SYS._startTime = 0
    
    function SYS:Initialize()
        self._distrib = {}

        self._startTime = CurTime()
    end

    function SYS:SetDistrib(room, value)
        self._distrib[room:GetName()] = math.Clamp(value, 0, 1)
    end

    function SYS:GetDistrib(room)
        return self._distrib[room:GetName()] or 1.0
    end
    
    function SYS:CalculatePowerNeeded()
        local totNeeded = 0
        for _, room in ipairs(self:GetShip():GetRooms()) do
            local cost = 1
            local shieldModule = room:GetModule(moduletype.SHIELDS)
            if shieldModule then
                cost = 1 - shieldModule:GetScore() * 0.75
            end
            if self:GetDistrib(room) > 0 then
                -- TODO: make continuous
                local needed = room:GetSurfaceArea() * SHIELD_POWER_PER_M2 * cost
                local goal = math.min(self:GetDistrib(room), room:GetMaximumShields())
                if room:GetShields() < goal - 0.001 then
                    totNeeded = totNeeded + needed * 2
                elseif room:GetShields() < goal + 0.001 then
                    totNeeded = totNeeded + needed * 0.5
                end
            end
        end
        return totNeeded
    end

    function SYS:Think(dt)
        local needed = self:GetPowerNeeded()
        local ratio = 0
        if needed > 0 then
            ratio = math.min(self:GetPower() / needed, 1)
        end

        for _, room in ipairs(self:GetShip():GetRooms()) do
            local goal = math.min(self:GetDistrib(room), room:GetMaximumShields())
            if goal > 0 then
                local score = 0
                local shieldModule = room:GetModule(moduletype.SHIELDS)
                if shieldModule then
                    score = shieldModule:GetScore() * 2
                end
                local rate = ratio * 2 * score - 1
                if room:GetShields() < goal - 0.001 or rate < 0 then
                    room:SetUnitShields(room:GetUnitShields() + SHIELD_RECHARGE_RATE * rate * dt)
                end
            end
            if room:GetShields() > goal or CurTime() < 10 then
                room:SetUnitShields(goal * room:GetSurfaceArea())
            end
        end
    end
elseif CLIENT then
    SYS.Icon = Material("systems/shields.png", "smooth")
end
