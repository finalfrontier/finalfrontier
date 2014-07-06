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

SYS.FullName = "Piloting"
SYS.SGUIName = "piloting"

SYS.Powered = true

local DURATION_MULTIPLIER = 4

function SYS:GetTargetCoordinates()
    local sx, sy = self:GetShip():GetCoordinates()
    local ax, ay = self:GetTargetAcceleration()

    local dt = self:GetAccelerationTime()

    return sx + ax * dt, sy + ay * dt
end

function SYS:GetTargetAcceleration()
    if self:IsFullStopping() then
        local vx, vy = self:GetShip():GetVel()
        local vl = math.sqrt(vx * vx + vy * vy)

        if vl == 0 then
            return 0, 0
        else
            return -vx / vl, -vy / vl
        end
    elseif self:GetAccelerationTime() <= 0 then
        return 0, 0
    end

    return self._nwdata.dx, self._nwdata.dy
end

function SYS:GetAccelerationTime()
    if self:IsFullStopping() then
        local vx, vy = self:GetShip():GetVel()
        return math.sqrt(vx * vx + vy * vy)
    end

    return math.max(0, self._nwdata.duration - CurTime() + self._nwdata.inittime)
end

function SYS:IsAccelerating()
    local ax, ay = self:GetTargetAcceleration()

    return ax * ax + ay * ay > 0
end

function SYS:IsFullStopping()
    return self._nwdata.fullstop
end

if SERVER then
    -- resource.AddFile("materials/systems/piloting.png")

    local ACCELERATION_PER_POWER = 1.0 / 100.0

    SYS._prevVel = Vector(0, 0, 0)

    local function shipPhysicsSimulate(ent, phys, delta)
        local self = ent._piloting

        if self:GetAccelerationTime() <= 0 then
            if self._nwdata.duration > 0 then
                self:SetTargetHeading(0, 0)
            end
            
            return Vector(0, 0, 0), Vector(0, 0, 0), SIM_GLOBAL_ACCELERATION
        end

        local dx, dy = self:GetTargetAcceleration()
        local a = self:GetAcceleration()

        local acc = universe:GetWorldPos(dx * a, dy * a) - universe:GetWorldPos(0, 0)
        return Vector(0, 0, 0), acc, SIM_GLOBAL_ACCELERATION
    end

    function SYS:GetMaximumPower()
        return 8
    end

    function SYS:CalculatePowerNeeded()
        local dx, dy = self:GetTargetAcceleration()

        if dx * dx + dy * dy > 0 then
            return self:GetMaximumPower()
        else
            return 0
        end
    end

    function SYS:Initialize()
        self:SetTargetHeading(0, 0)

        self:GetShip():GetObject()._piloting = self
        self:GetShip():GetObject().PhysicsSimulate = shipPhysicsSimulate
    end

    function SYS:FullStop()
        self._nwdata.fullstop = true
        self._nwdata.duration = 0
        self._nwdata.inittime = 0
        self._nwdata.dx = 0
        self._nwdata.dy = 0
        self:_UpdateNWData()
    end

    function SYS:SetTargetHeading(dx, dy)
        self._nwdata.fullstop = false
        self._nwdata.duration = math.sqrt(dx * dx + dy * dy) * DURATION_MULTIPLIER
        self._nwdata.inittime = CurTime()

        if self._nwdata.duration > 0 then
            self._nwdata.dx = dx / self._nwdata.duration
            self._nwdata.dy = dy / self._nwdata.duration

            self:GetShip():GetObject():SetTargetRotation(math.atan2(dy, dx) / math.pi * 180.0)
        else
            self._nwdata.dx = 0
            self._nwdata.dy = 0
        end

        self:_UpdateNWData()
    end

    function SYS:GetAcceleration()
        if self:GetPowerNeeded() <= 0 then return 0 end
        return self:GetPower() * ACCELERATION_PER_POWER
    end
elseif CLIENT then
    -- SYS.Icon = Material("systems/piloting.png", "smooth")
end
