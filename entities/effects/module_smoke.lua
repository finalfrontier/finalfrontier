function EFFECT:Init(data)
    local target = data:GetEntity()
    if not IsValid(target) then return end

    local mag = data:GetMagnitude()
    local low, high = target:WorldSpaceAABB()

    local count = math.Clamp(math.sqrt(mag) * 8, 4, 64)
        
    local emitter = ParticleEmitter(target:GetPos())
    for i = 1, count do
        local pos = Vector(
            math.Rand(low.x, high.x),
            math.Rand(low.y, high.y),
            math.Rand(low.z, high.z) + 16
        )

        local particle = emitter:Add("particle/SmokeStack", pos)
        if particle then
            particle:SetVelocity((pos - target:GetPos())
                * (5 + math.random() * 2))

            particle:SetGravity(Vector(0, 0, 0))
            particle:SetAirResistance(150)
            particle:SetDieTime(math.Rand(0.5, 1.5))

            particle:SetLifeTime(0)
            particle:SetStartAlpha(math.Rand(8, 16))
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(16, 32))
            particle:SetEndSize(math.Rand(32, 64))
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(0)
            
            particle:SetCollide(false)
            particle:SetBounce(0.1)
        end
    end
    emitter:Finish()

    if data:GetFlags() ~= 1 then
        target:EmitSound(table.Random(sparkSounds), 85 + (30 / 16 * mag), 100)
    end
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
    return
end
