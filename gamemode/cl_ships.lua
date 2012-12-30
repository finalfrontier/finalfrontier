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
	local ship = ships.FindByName(net.ReadString())
	ship:UpdateFromNet()
end)
