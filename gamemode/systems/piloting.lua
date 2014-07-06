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

local SNAPPING_THRESHOLD_POS = 1.0 / 16384.0
local SNAPPING_THRESHOLD_VEL = 1.0 / 16384.0

function SYS:GetTargetCoordinates()
    if self:ShouldFullStop() then
        local sx, sy = self:GetShip():GetCoordinates()
        local vx, vy = self:GetShip():GetObject():GetVel()
        return sx - vx * 4, sy - vy * 4
    end

    return self._nwdata.targetx, self._nwdata.targety
end

function SYS:ShouldFullStop()
    return self._nwdata.fullstop
end

if SERVER then
    -- resource.AddFile("materials/systems/piloting.png")

    local ACCELERATION_PER_POWER = 1.0 / 400.0

    local function findAccel1D(a, u, s)
        local v = math.sqrt(2 * a * math.abs(s)) * math.sign(s)
        if u < v then return math.min(a, v - u) end
        if u > v then return math.max(-a, v - u) end
        return 0
    end

    local function shipPhysicsSimulate(ent, phys, delta)
        local piloting = ent._piloting

        local x, y = ent:GetCoordinates()
        local tx, ty = piloting:GetTargetCoordinates()
        local dx, dy = universe:GetDifference(x, y, tx, ty)

        local vx, vy = ent:GetVel()
        if dx * dx + dy * dy <= SNAPPING_THRESHOLD_POS
            and vx * vx + vy * vy <= SNAPPING_THRESHOLD_VEL then
            piloting:SetTargetCoordinates(x, y, false)
            return Vector(0, 0, 0), -phys:GetVelocity(), SIM_GLOBAL_ACCELERATION
        end

        local a = piloting:GetAcceleration() * math.sqrt(0.5)

        local rot = ent:GetRotationRadians()
        local nx, ny = math.cos(rot), math.sin(rot)
        local rx, ry = -ny, nx

        local an = findAccel1D(a, vx * nx + vy * ny, (dx * nx + dy * ny) * 0.75)
        local ar = findAccel1D(a, vx * rx + vy * ry, (dx * rx + dy * ry) * 0.75)

        vx = vx * 0.99 + an * nx + ar * rx
        vy = vy * 0.99 + an * ny + ar * ry

        local vel = universe:GetWorldPos(vx, vy) - universe:GetWorldPos(0, 0)

        if not piloting:ShouldFullStop() then
            ent:SetTargetRotation(math.atan2(vy, vx) / math.pi * 180.0)
        end

        return Vector(0, 0, 0), vel - phys:GetVelocity(), SIM_GLOBAL_ACCELERATION
    end

    function SYS:GetMaximumPower()
        return 4
    end

    function SYS:CalculatePowerNeeded()
        local dx, dy = 0, 0

        if self:ShouldFullStop() then
            dx, dy = self:GetShip():GetVel()
        else
            local sx, sy = self:GetShip():GetCoordinates()
            local tx, ty = self:GetTargetCoordinates()
            dx, dy = universe:GetDifference(sx, sy, tx, ty)
        end
        
        if dx * dx + dy * dy > 0 then
            return self:GetMaximumPower()
        else
            return 0
        end
    end

    function SYS:Initialize()
        self._nwdata.targetx = 0
        self._nwdata.targety = 0
        self._nwdata.fullstop = true
        self:_UpdateNWData()

        self:GetShip():GetObject()._piloting = self
        self:GetShip():GetObject().PhysicsSimulate = shipPhysicsSimulate
    end

    function SYS:SetTargetCoordinates(x, y, fullStop)
        self._nwdata.fullstop = fullStop

        if fullStop then
            local sx, sy = self:GetShip():GetCoordinates()
            x, y = universe:GetDifference(sx, sy, x, y)

            local len = math.sqrt(x * x + y * y)

            x, y = x / len, y / len
        end
        
        self._nwdata.targetx, self._nwdata.targety = x, y

        self:_UpdateNWData()
    end

    function SYS:GetAcceleration()
        if self:GetPowerNeeded() <= 0 then return 0 end
        return self:GetPower() * ACCELERATION_PER_POWER
    end
elseif CLIENT then
    -- SYS.Icon = Material("systems/piloting.png", "smooth")
end
