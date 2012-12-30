
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
		local door = { _lastUpdate = 0 }
		door.x = net.ReadFloat()
		door.y = net.ReadFloat()
		door.angle = net.ReadFloat()
		
		door.Bounds = Bounds()
		local coords = {
			{ x = -32, y = -64 },
			{ x = -32, y =  64 },
			{ x =  32, y =  64 },
			{ x =  32, y = -64 }
		}
		local trans = Transform2D()
		trans:Rotate(door.angle * math.pi / 180)
		trans:Translate(door.x, door.y)
		for i, v in ipairs(coords) do
			door.Bounds:AddPoint(trans:Transform(v.x, v.y))
		end

		local roomai = net.ReadInt(8)
		local roombi = net.ReadInt(8)
		door.Open = false
		door.Locked = false
		door.Rooms = { self._roomlist[roomai], self._roomlist[roombi] }
		
		table.insert(door.Rooms[1].Doors, door)
		table.insert(door.Rooms[2].Doors, door)
		table.insert(self.Doors, door)
	end
end

function _mt:UpdateFromNet()
	local timestamp = net.ReadFloat()
	while true do
		local index = net.ReadInt(8)
		if index == 0 then break end
		local room = self._roomlist[index]
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

function _mt:AddRoom(room)
	self.Rooms[room.Name] = room
	self._roomlist[room.Index] = room

	self.Bounds:AddBounds(room.Bounds)
end

function _mt:AddDoor(door)
	table.insert(self.Doors, door)
end

function Ship()
	local ship = {}

	ship.Rooms = {}
	ship._roomlist = {}
	ship.Doors = {}
	ship.Bounds = Bounds()

	return setmetatable(ship, _mt)
end