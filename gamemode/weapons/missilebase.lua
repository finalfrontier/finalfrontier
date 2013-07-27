local BASE = "base"

WPN.BaseName = BASE

WPN.Projectile = true

WPN.Homing = true
WPN.Speed = { 1 / 16, 1 / 16 }
WPN.Lateral = { 1, 1 }
WPN.LifeTime = { 8, 8 }

function WPN:IsHoming()
    return self.Homing
end

function WPN:GetSpeed()
    return self:_FindValue(self.Speed)
end

function WPN:GetLateral()
    return self:_FindValue(self.Lateral)
end

function WPN:GetLifeTime()
    return self:_FindValue(self.LifeTime)
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
