ships = {}

ships._dict = {}

function ships.AddShip(ship)
	ships._dict[ship.Name] = ship
end

function ships.FindByName(name)
	return ships._dict[name]
end

net.Receive("InitShipData", function(len)
	local ship = Ship()
	ship:ReadFromNet()
	ships.AddShip(ship)
end)

net.Receive("ShipStateUpdate", function(len)
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
