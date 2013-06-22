ENT.Type = "point"
ENT.Base = "base_point"

dmgeffect = {}
dmgeffect.none = 0
dmgeffect.sparks = 1
dmgeffect.gas = 2
dmgeffect.smoke = 4
dmgeffect.cracks = 8

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

function ENT:Think()
    if self:IsActive() and CurTime() >= self._nextBurst then
        if self:GetType() == dmgeffect.sparks then
            local ed = EffectData()
            ed:SetOrigin(self:GetPos())
            ed:SetAngles(self:GetAngles())
            util.Effect("dmg_sparks", ed, true, true)

            self._nextBurst = CurTime() + math.random() * 4 + 2
        end
    end
end
