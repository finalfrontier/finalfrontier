WPN.MaxTier = 5

WPN.MaxPower = { 1, 3 }
WPN.MaxCharge = { 10, 40 }
WPN.ShotCharge = { 10, 40 }

WPN.Projectile = true
WPN.Homing = true
WPN.Speed = { 1, 2 }
WPN.Lateral = { 1, 4 }
WPN.LifeTime = { 4, 8 }

WPN.BaseDamage = { 10, 50 }
WPN.PierceRatio = { 0, 0 }

if CLIENT then
    WPN.FullName = "Missile"
    WPN.Color = Color(255, 255, 255, 255)
end

function WPN:_FindValue(values)
    if type(values) == "number" then return values end
    if self.MaxTier == 1 then return (values[1] + values[2]) * 0.5 end
    local t = (self:GetTier() - 1) / (self.MaxTier - 1)
    return values[1] + t * (values[2] - values[1])
end

function WPN:GetMaxPower()
    return self:_FindValue(self.MaxPower)
end

function WPN:GetMaxCharge()
    return self:_FindValue(self.MaxCharge)
end

function WPN:GetShotCharge()
    return self:_FindValue(self.ShotCharge)
end

function WPN:IsProjectile()
    return self.Projectile
end

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

function WPN:GetBaseDamage()
    return self:_FindValue(self.BaseDamage)
end

function WPN:GetPierceRatio()
    return self:_FindValue(self.PierceRatio)
end

if SERVER then
    function WPN:CreateDamageInfo(target, damage)
        if not IsValid(target) then return nil end
        
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetDamage(damage)
    end

    function WPN:OnHit(room)
        local shields = room:GetUnitShields()
        local damage = self:GetBaseDamage()
        local ratio = self:GetPierceRatio()

        room:SetUnitShields(shields - math.min(shields, damage) * (1 - ratio))
        damage = damage - math.min(damage, shields) * ratio

        for _, ent in pairs(room:GetEntities()) do
            local dmg = self:CreateDamageInfo(ent, damage)
            if dmg then
                dmg:SetAttacker(room)
                dmg:SetInflictor(room)
                ent:TakeDamageInfo(dmg)
            end
        end
    end
elseif CLIENT then
    function WPN:GetFullName()
        return self.FullName
    end

    function WPN:GetColor()
        return self.Color
    end
end
