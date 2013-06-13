ENT.Type = "point"
ENT.Base = "base_point"

ENT._nextnames = nil
ENT._roomname = nil

function ENT:_AddNextName(name)
    if not self._nextnames then self._nextnames = {} end
    if table.HasValue(self._nextnames, name) then return end

    table.insert(self._nextnames, name)
end

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomname = tostring(value)
    elseif string.find(key, "^next[1-9][0-9]*") then
        self:_AddNextName(tostring(value))
    end
end

function ENT:InitPostEntity()
    if self._roomname then
        local rooms = ents.FindByName(self._roomname)
        if #rooms > 0 then
            local room = rooms[1]
            local pos = self:GetPos()
            room:AddDetail(self:GetName(), pos.x, pos.y, self._nextnames or {})
        end
    end
    
    self:Remove()
end
