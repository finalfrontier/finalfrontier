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

SYS.FullName = "Sensors"
SYS.SGUIName = "sensors"

SYS.Powered = true

function SYS:GetMaximumCharge()
    return self._nwdata.maxcharge
end

function SYS:GetCurrentCharge()
    return math.min(self._nwdata.charge, self._nwdata.maxcharge)
end

function SYS:IsScanning()
    return self._nwdata.activeScanDist > 0
end

function SYS:GetActiveScanDistance()
    return self._nwdata.activeScanDist
end

function SYS:CanScan()
    return self:GetCurrentCharge() >= self:GetMaximumCharge()
end

if SERVER then
    resource.AddFile("materials/systems/sensors.png")

    local RECHARGE_RATE = 1 / 10
    local SCAN_SPEED = 0.1

    SYS._scanning = false

    function SYS:Initialize()
        self._nwdata.maxcharge = 1
        self._nwdata.charge = 0
        self._nwdata.activeScanDist = 0
        self:_UpdateNWData()
    end

    function SYS:Think(dt)
        local needsUpdate = false

        local newMax = math.max(1, self:GetRoom():GetModuleScore(moduletype.systempower) * 4)
        if newMax ~= self._nwdata.maxcharge then
            self._nwdata.maxcharge = newMax
            needsUpdate = true
        end

        if self._nwdata.charge < self._nwdata.maxcharge then
            self._nwdata.charge = math.min(self._nwdata.maxcharge, self._nwdata.charge
                + RECHARGE_RATE * dt * self:GetPower())
            needsUpdate = true
        elseif self._nwdata.charge > self._nwdata.maxcharge then
            self._nwdata.charge = self._nwdata.maxcharge
            needsUpdate = true
        end

        if self._scanning then
            self._nwdata.activeScanDist = self._nwdata.activeScanDist + SCAN_SPEED
            if self._nwdata.activeScanDist > self:GetShip():GetScanRange() then
                self._nwdata.activeScanDist = 0
                self._scanning = false
            end
            needsUpdate = true
        end

        if needsUpdate then
            self:_UpdateNWData()
        end
    end

    function SYS:StartScan()
        if not self:CanScan() then return end

        self._scanning = true
        self._nwdata.charge = 0
        self:_UpdateNWData()
    end

    function SYS:CalculatePowerNeeded()
        if self:GetCurrentCharge() < self:GetMaximumCharge() then
            return 2
        end
        return 0
    end

elseif CLIENT then
    SYS.Icon = Material("systems/sensors.png", "smooth")
end
