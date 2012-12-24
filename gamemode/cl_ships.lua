ships = {}

ships._dict = {}

function ships.FindByName(name)
	return ships._dict[name]
end

net.Receive("InitShipData", function(len)
	local name = net.ReadString()
	local roomCount = net.ReadInt(8)
	
	local ship = {}
	ship.Rooms = {}
	ship._roomlist = {}
	ship.Doors = {}
	ship.Bounds = Bounds()
	
	for rNum = 1, roomCount do
		local room = Room()
		room.Ship = ship
		room.Name = net.ReadString()
		room.Index = net.ReadInt(8)
		room.System = sys.Create(net.ReadString(), room)
		room.Bounds = Bounds()
		room.Doors = {}
		
		room.Corners = {}
		local cornerCount = net.ReadInt(8)
		for cNum = 1, cornerCount do
			local index = net.ReadInt(8)
			local pos = { x = net.ReadFloat(), y = net.ReadFloat() }
			
			room.Corners[index] = pos
			room.Bounds:AddPoint(pos.x, pos.y)
		end
		
		room.ConvexPolys = FindConvexPolygons(room.Corners)
		
		ship.Rooms[room.Name] = room
		ship.Bounds:AddBounds(room.Bounds)
	
		ship._roomlist[room.Index] = room
	end
	
	local doorCount = net.ReadInt(8)
	for dNum = 1, doorCount do
		local door = { _lastUpdate = 0 }
		door.x = net.ReadFloat()
		door.y = net.ReadFloat()
		door.angle = net.ReadFloat()
		
		door.Bounds = Bounds()
		local roomai = net.ReadInt(8)
		local roombi = net.ReadInt(8)
		door.Open = false
		door.Locked = false
		door.Rooms = { ship._roomlist[roomai], ship._roomlist[roombi] }
		
		table.insert(door.Rooms[1].Doors, door)
		table.insert(door.Rooms[2].Doors, door)
		table.insert(ship.Doors, door)
	end
	
	ships._dict[name] = ship
end)

net.Receive("ShipRoomStates", function(len)
	local timestamp = net.ReadFloat()
	local name = net.ReadString()
	local ship = ships.FindByName(name)
	while true do
		local index = net.ReadInt(8)
		if index == 0 then break end
		local room = ship._roomlist[index]
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
		local door = ship.Doors[index]
		if timestamp > door._lastUpdate then
			local flags = net.ReadInt(8)
			if flags % 2 >= 1 then door.Open = true else door.Open = false end
			if flags % 4 >= 2 then door.Locked = true else door.Locked = false end
			door._lastUpdate = timestamp
		end
	end
end)
