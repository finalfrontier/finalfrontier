ENT.Type = "point"
ENT.Base = "base_point"

local types

ENT._roomName = nil
ENT._moduleType = 0

ENT._room = nil

function ENT:GetRoom()
    return self._room
end

function ENT:GetModuleType()
    return self._moduleType
end

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomName = tostring(value)
    elseif key == "type" then
        self._moduleType = tonumber(value)
    end
end

function ENT:InitPostEntity()
    if self._roomName then
        local rooms = ents.FindByName(self._roomName)
        if #rooms > 0 then
            self._room = rooms[1]
            self._room:AddModuleSlot(self:GetPos(), self._moduleType)
        end
    end
end
