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

SYS.FullName = "Reactor"
SYS.SGUIName = "reactor"

SYS.Powered = false

if SERVER then
    resource.AddFile("materials/systems/reactor.png")

    SYS._limits = nil

    function SYS:Initialize()
        self._limits = {}

        self._nwdata.total = 0
        self._nwdata.needed = 0
        self._nwdata.supplied = 0
    end

    function SYS:SetSystemLimitRatio(system, limit)
        self._limits[system.Name] = limit
    end

    function SYS:GetSystemLimitRatio(system)
        return self._limits[system.Name] or 1.0
    end

    function SYS:GetSystemLimit(system)
        return self:GetSystemLimitRatio(system) * self:GetTotalPower()
    end

    function SYS:CaculatePower(dt)
        local totalneeded = 0
        for _, room in pairs(self:GetShip():GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                local needed = room:GetSystem():CalculatePowerNeeded(dt)
                room:GetSystem():SetPowerNeeded(needed)
                local powerModule = room:GetModule(moduletype.SYSTEM_POWER)
                if IsValid(powerModule) and powerModule.GetDamaged then
                    needed = needed * (1 - powerModule:GetDamaged() / 16)
                else
                    needed = 0
                end
                local limit = self:GetSystemLimit(room:GetSystem())
                totalneeded = totalneeded + math.min(needed, limit)
            end
        end

        self._nwdata.needed = totalneeded

        local ratio = 0
        if totalneeded > 0 then
            ratio = math.min(1, self:GetTotalPower() / totalneeded)
        end

        self._nwdata.supplied = ratio * totalneeded

        for _, room in pairs(self:GetShip():GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                local needed = room:GetSystem():CalculatePowerNeeded(dt)
                local powerModule = room:GetModule(moduletype.SYSTEM_POWER)
                if powerModule then
                    needed = needed * (1 - powerModule:GetDamaged() / 16)
                else
                    needed = 0
                end
                local limit = self:GetSystemLimit(room:GetSystem())
                room:GetSystem():SetPower(math.min(needed, limit) * ratio)
            end
        end

        self._nwdata.total = self:GetTotalPower()

        self._nwdata:Update()
    end

    function SYS:Think(dt)
        self:CaculatePower(dt)
    end

    function SYS:GetTotalPower()
        local score = self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)
        return 5 + score * 20
    end
elseif CLIENT then
    SYS.Icon = Material("systems/reactor.png", "smooth")

    function SYS:GetTotalPower()
        return self._nwdata.total
    end
end

function SYS:GetTotalNeeded()
    return self._nwdata.needed
end

function SYS:GetTotalSupplied()
    return self._nwdata.supplied
end

