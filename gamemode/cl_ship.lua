local _mt = {}
_mt.__index = _mt

function _mt:ReadFromNet()
	self.Name = net.ReadString()
	
	local roomCount = net.ReadInt(8)
	for rNum = 1, roomCount do
		local room = Room(self)
		room:ReadFromNet()
		self:AddRoom(room)
	end
	
	local doorCount = net.ReadInt(8)
	for dNum = 1, doorCount do
		local door = Door(self)
		door:ReadFromNet()
		self:AddDoor(door)
	end
end

function _mt:UpdateFromNet()
	local timestamp = net.ReadFloat()
	while true do
		local index = net.ReadInt(8)
		if index == 0 then break end
		local room = self._roomlist[index]
		if not room then return end
		if timestamp > room._lastUpdate then
			room._oldTemp = room._temperature
			room._oldAtmo = room._atmosphere
			room._oldShld = room._shields
			
			room._temperature = net.ReadFloat()
			room._atmosphere = net.ReadFloat()
			room._shields = net.ReadFloat()
			
			room._lastUpdate = timestamp
		end
	end
	while true do
		local index = net.ReadInt(8)
		if index == 0 then break end
		local door = self.Doors[index]
		if timestamp > door._lastUpdate then
			local flags = net.ReadInt(8)
			if flags % 2 >= 1 then door.Open = true else door.Open = false end
			if flags % 4 >= 2 then door.Locked = true else door.Locked = false end
			door._lastUpdate = timestamp
		end
	end
end

function _mt:GetName()
	return self.Name
end

function _mt:AddRoom(room)
	self.Rooms[room.Name] = room
	self._roomlist[room.Index] = room

	self.Bounds:AddBounds(room.Bounds)
end

function _mt:GetRooms()
	return self._roomlist
end

function _mt:GetRoomByIndex(index)
	return self._roomlist[index]
end

function _mt:AddDoor(door)
	table.insert(self.Doors, door)
end

function _mt:FindTransform(screen, x, y, width, height)
	local bounds = Bounds(x, y, width, height)
	return FindBestTransform(self.Bounds, bounds, true, true)
end

function _mt:ApplyTransform(transform)
	for _, room in pairs(self.Rooms) do
		room:ApplyTransform(transform)
	end

	for _, door in ipairs(self.Doors) do
		door:ApplyTransform(transform)
	end
end

function _mt:Draw(screen, roomColorFunc, doorColorFunc)
	for _, room in pairs(self.Rooms) do
		room:Draw(screen, roomColorFunc)
	end

	for _, door in ipairs(self.Doors) do
		door:Draw(screen, doorColorFunc)
	end
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetShip()
	if not self:GetNWString("ship") then return nil end
	return ships.FindByName(self:GetNWString("ship"))
end

function Ship()
	local ship = {}

	ship.Rooms = {}
	ship._roomlist = {}
	ship.Doors = {}
	ship.Bounds = Bounds()

	return setmetatable(ship, _mt)
end
