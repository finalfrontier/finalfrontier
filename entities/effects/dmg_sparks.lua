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

local sparkSounds = {
    "ambient/energy/spark1.wav",
    "ambient/energy/spark2.wav",
    "ambient/energy/spark3.wav",
    "ambient/energy/spark4.wav",
    "ambient/energy/spark5.wav",
    "ambient/energy/spark6.wav"
}

function EFFECT:Init(data)
    local mag = math.random()
    local count = mag * 12 + 4
    local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local dir = ang:Forward()
    local up = ang:Up()
    local right = ang:Right()

    local emitter = ParticleEmitter(pos)
    for i = 1, count do
        local particle = emitter:Add("effects/spark", pos
            + (math.random() * 16 - 8) * up
            + (math.random() * 16 - 8) * right)
        if particle then
            particle:SetVelocity(dir * (math.random() * 128 + 32)
                + (math.random() * 128 - 64) * up
                + (math.random() * 128 - 64) * right)

            particle:SetGravity(Vector(0, 0, -600))
            particle:SetAirResistance(100)
            particle:SetDieTime(math.Rand(0.5, 1.5))

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

    sound.Play(table.Random(sparkSounds), pos, 55 + (30 * mag), 100)
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
    return
end
