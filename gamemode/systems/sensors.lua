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
    return self._nwdata.maxcharge or 0
end

function SYS:GetCurrentCharge()
    return math.min(self._nwdata.charge or 0, self._nwdata.maxcharge or 0)
end

function SYS:IsScanning()
    return self:GetScanProgress() > 0
end

function SYS:CanScan()
    return self:GetCurrentCharge() >= self:GetMaximumCharge()
end

function SYS:GetRange()
    return self:GetBaseScanRange() + math.min(self:GetScanProgress(), 1)
        * (self:GetLongScanRange() - self:GetBaseScanRange())
end

function SYS:GetScanSpeed()
    return self._nwdata.scanspeed or 2
end

function SYS:GetScanDelay()
    return self._nwdata.scandelay or 5
end

function SYS:GetScanProgress()
    local t = CurTime() - (self._nwdata.scanstart or -1000)

    if t < self:GetScanSpeed() then
        return math.Clamp(t / self:GetScanSpeed(), 0, 1)
    end

    t = t - self:GetScanSpeed()

    if t <= self:GetScanDelay() then
        return 1 + math.Clamp(t / self:GetScanDelay(), 0, 1)
    else
        return 0
    end
end

function SYS:GetBaseScanRange()
    return self._nwdata.baserange or 0.1
end

function SYS:GetLongScanRange()
    return self._nwdata.scanrange or 0.1
end

function SYS:IsAutoScan()
    return self._nwdata.autoscan
end

if SERVER then
    resource.AddFile("materials/systems/sensors.png")

    local RECHARGE_RATE = 1 / 10
    local SCAN_SPEED = 0.1

    SYS._oldScore = 0

    function SYS:Initialize()
        self._nwdata.maxcharge = 1
        self._nwdata.charge = 0
        self._nwdata.baserange = 0.25
        self._nwdata.scanrange = 2.0
        self._nwdata.scanspeed = 2
        self._nwdata.scandelay = 5
        self._nwdata.scanstart = -1000
        self._nwdata.autoscan = false
        self._nwdata:Update()
    end

    function SYS:Think(dt)
        local needsUpdate = false

        local score = self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)

        if score ~= self._oldScore then
            self._oldScore = score

            self._nwdata.maxcharge = math.max(1, 8 - score * 6)
            self._nwdata.baserange = 0.2 + score * 0.8
            self._nwdata.scanrange = 2.0 + score * 2.0
            self._nwdata.scanspeed = 5 - score * 2.5
            self._nwdata.scandelay = 5 + score * 5

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

        if self._nwdata.charge == self._nwdata.maxcharge and self:IsAutoScan() then
            self:StartScan()
        end

        if needsUpdate then
            self._nwdata:Update()
        end
    end

    function SYS:SetAutoScan(val)
        self._nwdata.autoscan = val ~= false
        self._nwdata:Update()
    end

    function SYS:StartScan()
        if not self:CanScan() then return end

        self._nwdata.scanstart = CurTime()
        self._nwdata.charge = 0
        self._nwdata:Update()
    end

    function SYS:CalculatePowerNeeded()
        if self:GetCurrentCharge() < self:GetMaximumCharge() then
            return 2 + self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)
        end
        return 0
    end

elseif CLIENT then
    SYS.Icon = Material("systems/sensors.png", "smooth")
end
