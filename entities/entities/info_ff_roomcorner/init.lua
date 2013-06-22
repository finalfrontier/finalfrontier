ENT.Type = "point"
ENT.Base = "base_point"

ENT._index = 0
ENT._roomName = nil

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomName = tostring(value)
    elseif key == "index" then
        self._index = tonumber(value)
    end
end

function ENT:InitPostEntity()
    if self._roomName then
        local rooms = ents.FindByName(self._roomName)
        if #rooms > 0 then
            local room = rooms[1]
            local pos = self:GetPos()
            room:AddCorner(self._index, pos.x, pos.y)
        end
    end
    
    self:Remove()
end
