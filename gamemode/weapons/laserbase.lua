local BASE = "base"

WPN.BaseName = BASE

WPN.Projectile = false

WPN.Arc = { 0, 0 }
WPN.Pulses = { 1, 1 }

function WPN:GetArc()
    return self:_FindValue(self.Arc)
end

function WPN:GetPulses()
    return self:_FindValue(self.Pulses)
end

if SERVER then
    function WPN:OnShoot(ship, target, rot)
        local sx, sy = ship:GetCoordinates()
        local tx, ty = target:GetCoordinates()
        local dx, dy = universe:GetDifference(sx, sy, tx, ty)
        if not rot then rot = math.atan2(dy, dx) / math.pi * 180 end

        weapon.LaunchMissile(ship, self, target, rot)
    end
end
