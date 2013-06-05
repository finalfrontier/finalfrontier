ENT.Type = "point"
ENT.Base = "base_point"

ENT._roomName = nil
ENT._transPad = false

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomName = tostring(value)
    elseif key == "transpad" then
        self._transPad = true
    end
end

function ENT:InitPostEntity()
    if self._roomName then
        local rooms = ents.FindByName(self._roomName)
        if #rooms > 0 then
            local room = rooms[1]
            room:AddTransporterTarget(self:GetPos(), self._transPad)
        end
    end
    
    self:Remove()
end
