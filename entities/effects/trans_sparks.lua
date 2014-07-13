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

function EFFECT:Init(data)    
    local low = data:GetOrigin()
    local high = data:GetStart()

    local offset = (low + high) / 2

    local size = high - low

    local count = math.Clamp(size.x * size.y * size.z / 256, 32, 128)
        
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

function EFFECT:Think()
    return false
end

function EFFECT:Render()
    return
end
