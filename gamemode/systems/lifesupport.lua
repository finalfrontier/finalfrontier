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

SYS.FullName = "Life Support"
SYS.SGUIName = "lifesupport"

SYS.Powered = true

if SERVER then
    resource.AddFile("materials/systems/lifesupport.png")

    local TEMP_POWER_PER_METER3 = 0.25
    local TEMP_RECHARGE_RATE = 5
    local ATMO_POWER_PER_METER3 = 0.5
    local ATMO_RECHARGE_RATE = 5

    SYS._atmo = nil
    SYS._temp = nil

    function SYS:Initialize()
        self._atmo = {}
        self._temp = {}
    end

    function SYS:SetGoalAtmosphere(room, value)
        self._atmo[room:GetName()] = value
    end

    function SYS:GetGoalAtmosphere(room)
        return self._atmo[room:GetName()] or 1.0
    end

    function SYS:SetGoalTemperature(room, value)
        self._temp[room:GetName()] = value
    end

    function SYS:GetGoalTemperature(room)
        return self._temp[room:GetName()] or 300
    end

    function SYS:CalculatePowerNeeded(dt)
        local totNeeded = 0
        for _, room in ipairs(self:GetShip():GetRooms()) do
            local score = 0
            local cost = 1
            local lifeModule = room:GetModule(moduletype.LIFE_SUPPORT)
            if lifeModule then
                score = lifeModule:GetScore()
                cost = 1 - score * 0.75
            end
            if self:GetGoalTemperature(room) ~= -1 then
                totNeeded = totNeeded + CalculatePowerCost(
                    room:GetUnitTemperature(),
                    self:GetGoalTemperature(room) / 600 * room:GetVolume(),
                    TEMP_RECHARGE_RATE * score * dt,
                    TEMP_POWER_PER_METER3 * cost)
            end
            if self:GetGoalAtmosphere(room) ~= -1 then
                totNeeded = totNeeded + CalculatePowerCost(
                    room:GetAirVolume(),
                    self:GetGoalAtmosphere(room) * room:GetVolume(),
                    ATMO_RECHARGE_RATE * score * dt,
                    ATMO_POWER_PER_METER3 * cost)
            end
        end
        return totNeeded
    end

    function SYS:Think(dt)
        if self:GetPower() <= 0 then return end

        local needed = self:GetPowerNeeded()
        local ratio = 0
        if needed > 0 then
            ratio = math.min(self:GetPower() / needed, 1)
        end

        for _, room in ipairs(self:GetShip():GetRooms()) do
            local score = 0
            local cost = 1
            local lifeModule = room:GetModule(moduletype.LIFE_SUPPORT)
            if lifeModule then
                score = lifeModule:GetScore() * 2
                cost = 2 - score * 0.5
            end
            if self:GetGoalTemperature(room) ~= -1 then
                room:SetUnitTemperature(CalculateNextValue(
                    room:GetUnitTemperature(),
                    self:GetGoalTemperature(room) / 600 * room:GetVolume(),
                    TEMP_RECHARGE_RATE * score * dt,
                    ratio))
            end
            if self:GetGoalAtmosphere(room) ~= -1 then
                room:SetAirVolume(CalculateNextValue(
                    room:GetAirVolume(),
                    self:GetGoalAtmosphere(room) * room:GetVolume(),
                    ATMO_RECHARGE_RATE * score * dt,
                    ratio))
            end
        end
    end
elseif CLIENT then
    SYS.Icon = Material("systems/lifesupport.png", "smooth")
end
