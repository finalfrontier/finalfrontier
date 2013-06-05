ENT.Type = "point"
ENT.Base = "base_point"

ENT._roomName = nil

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomName = tostring(value)
    end
end

function ENT:InitPostEntity()
    if self._roomName then
        local rooms = ents.FindByName(self._roomName)
        if #rooms > 0 then
            local room = rooms[1]
            room:AddTransporterTarget(self:GetPos())
        end
    end
    
    self:Remove()
end
