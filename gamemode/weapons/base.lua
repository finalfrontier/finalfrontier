WPN.FullName = "Base Weapon"

WPN.MaxPower = 1
WPN.MaxCharge = 10
WPN.ShotCharge = 10

WPN.Projectile = true
WPN.Homing = true

WPN.Speed = 1
WPN.Lateral = 1

WPN.LifeTime = 5

WPN.BaseDamage = 20
WPN.PierceRatio = 0

function WPN:GetMaxPower()
    return self.MaxPower
end

function WPN:GetMaxCharge()
    return self.MaxCharge
end

function WPN:GetShotCharge()
    return self.ShotCharge
end

function WPN:IsProjectile()
    return self.Projectile
end

function WPN:IsHoming()
    return self.Homing
end

function WPN:GetSpeed()
    return self.Speed
end

function WPN:GetLateral()
    return self.Lateral
end

function WPN:GetLifeTime()
    return self.LifeTime
end

function WPN:GetBaseDamage()
    return self.BaseDamage
end

function WPN:GetPierceRatio()
    return self.PierceRatio
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
end
