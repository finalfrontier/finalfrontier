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

ENT.Type = "point"
ENT.Base = "base_point"

dmgeffect = {}
dmgeffect.NONE = 0
dmgeffect.SPARKS = 1
dmgeffect.GAS = 2
dmgeffect.SMOKE = 4
dmgeffect.CRACKS = 8

ENT._roomname = nil
ENT._room = nil
ENT._type = 0
ENT._active = false
ENT._nextBurst = 0

function ENT:GetRoom()
    return self._room
end

function ENT:GetType()
    return self._type
end

function ENT:SetActive(active)
    self._active = active
    self._nextBurst = 0
end

function ENT:IsActive()
    return self._active
end

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomname = tostring(value)
    elseif key == "type" then
        self._type = tonumber(value)
    end
end

function ENT:InitPostEntity()
    if self._roomname then
        local rooms = ents.FindByName(self._roomname)
        if #rooms > 0 then
            self._room = rooms[1]
            self._room:AddDamageEffect(self)
        end
    end
end

function ENT:PlayEffect()
    if self:GetType() == dmgeffect.SPARKS then
        local ed = EffectData()
        ed:SetOrigin(self:GetPos())
        ed:SetAngles(self:GetAngles())
        util.Effect("dmg_sparks", ed, true, true)

        self._nextBurst = CurTime() + math.random() * 4 + 2
    end
end

function ENT:Think()
    if self:IsActive() and CurTime() >= self._nextBurst then
        self:PlayEffect()
    end
end
