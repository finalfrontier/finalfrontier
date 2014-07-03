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

function SYS:GetTargetCoordinates()
    if self:IsRelative() then
        local sx, sy = self:GetShip():GetCoordinates()
        return sx + self._nwdata.targetx, sy + self._nwdata.targety
    end
    return self._nwdata.targetx, self._nwdata.targety
end

function SYS:IsRelative()
    return self._nwdata.relative
end

if SERVER then
    -- resource.AddFile("materials/systems/piloting.png")

    local SNAPPING_THRESHOLD_POS = 1.0 / 65536.0
    local SNAPPING_THRESHOLD_VEL = 1.0 / 16384.0

    local ACCELERATION_PER_POWER = 1.0 / 800.0

    local function findAccel1D(g, a, p, u)
        local s = g - p
        local v = math.sqrt(2 * a * math.abs(s)) * math.sign(s)
        if u < v then return math.min(a, v - u) end
        if u > v then return math.max(-a, v - u) end
        return 0
    end

    local function shipPhysicsSimulate(ent, phys, delta)
        local x, y = ent:GetCoordinates()
        local tx, ty = ent._piloting:GetTargetCoordinates()
        local dx, dy = universe:GetDifference(x, y, tx, ty)

        local vx, vy = ent:GetVel()
        if dx * dx + dy * dy <= SNAPPING_THRESHOLD_POS
            and vx * vx + vy * vy <= SNAPPING_THRESHOLD_VEL then
            ent:SetCoordinates(tx, ty)
            return Vector(0, 0, 0), -phys:GetVelocity(), SIM_GLOBAL_ACCELERATION
        end
        vx = vx * 0.99
        vy = vy * 0.99

        local a = ent._piloting:GetAcceleration() * math.sqrt(0.5)

        local ax = findAccel1D(x + dx, a, x, vx)
        local ay = findAccel1D(y + dy, a, y, vy)

        local vel = universe:GetWorldPos(vx + ax, vy + ay) - universe:GetWorldPos(0, 0)
        ent:SetTargetRotation(math.atan2(vy, vx) / math.pi * 180.0)
        return Vector(0, 0, 0), vel - phys:GetVelocity(), SIM_GLOBAL_ACCELERATION
    end

    function SYS:GetMaximumPower()
        return 4
    end

    function SYS:CalculatePowerNeeded()
        local sx, sy = self:GetShip():GetCoordinates()
        local tx, ty = self:GetTargetCoordinates()
        local dx, dy = universe:GetDifference(sx, sy, tx, ty)
        if dx * dx + dy * dy > 0 then
            return self:GetMaximumPower()
        else
            return 0
        end
    end

    function SYS:Initialize()
        self._nwdata.targetx = 0
        self._nwdata.targety = 0
        self._nwdata.relative = true
        self:_UpdateNWData()

        self:GetShip():GetObject()._piloting = self
        self:GetShip():GetObject().PhysicsSimulate = shipPhysicsSimulate
    end

    function SYS:SetTargetCoordinates(x, y, relative)
        self._nwdata.relative = relative

        if relative then
            local sx, sy = self:GetShip():GetCoordinates()
            self._nwdata.targetx, self._nwdata.targety = universe:GetDifference(sx, sy, x, y)
        else
            self._nwdata.targetx = x
            self._nwdata.targety = y
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
