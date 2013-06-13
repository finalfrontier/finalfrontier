function EFFECT:Init(data)
    local target = data:GetEntity()
    if not IsValid(target) then return end
    
    local offset = data:GetOrigin()
    local low, high = target:WorldSpaceAABB()
    low = low - target:GetPos() + offset
    high = high - target:GetPos() + offset

    local count = math.Clamp(target:BoundingRadius() * 4, 32, 256)
        
    local emitter = ParticleEmitter(offset)
    for i = 1, count do
        local pos = Vector(
        	math.Rand(low.x, high.x),
        	math.Rand(low.y, high.y),
        	math.Rand(low.z,high.z)
        )

        local particle = emitter:Add("effects/spark", pos)
        if particle then
            if math.random() < 0.5 then
                particle:SetVelocity((pos - offset) * (5 + math.random() * 5))
                particle:SetGravity(Vector(0, 0, -600))
                particle:SetAirResistance(100)
                particle:SetDieTime(math.Rand(1.5, 2.5))
            else
                particle:SetVelocity((pos - offset) * 1)
                particle:SetGravity(Vector(0, 0, -100))
                particle:SetAirResistance(100)
                particle:SetDieTime(math.Rand( 0.5, 1.0 ))
            end

            particle:SetLifeTime(0)
            particle:SetStartAlpha(math.Rand(191, 255))
            particle:SetEndAlpha(0)
            particle:SetStartSize(2)
            particle:SetEndSize(0)
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(0)
            
            particle:SetCollide(true)
            particle:SetBounce(0.3)
        end
    end
    emitter:Finish()
end

function EFFECT:Think( )
    return false
end

function EFFECT:Render()
    return
end
