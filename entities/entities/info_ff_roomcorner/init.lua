ENT.Type = "point"
ENT.Base = "base_point"

ENT.Index = 0
ENT.RoomName = nil

function ENT:KeyValue(key, value)
	if key == "room" then
		self.RoomName = tostring(value)
	elseif key == "index" then
		self.Index = tonumber(value)
	end
end

function ENT:InitPostEntity()
	if self.RoomName then
		local rooms = ents.FindByName(self.RoomName)
		if #rooms > 0 then
			local room = rooms[1]
			local pos = self:GetPos()
			room:AddCorner(self.Index, pos.x, pos.y)
		end
	end
	
	self:Remove()
end

function ENT:AddRoom(room)
	local name = room:GetName()
	if not name then return end

	self.Rooms[name] = room
end
