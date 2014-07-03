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
