ships = {}

ships._dict = {}
ships._nwdata = GetGlobalTable("ships")

function ships.AddShip(ship)
	ships._dict[ship:GetName()] = ship
end

function ships.GetByName(name)
	return ships._dict[name]
end

function ships.GetRoomByName(name)
    for _, ship in pairs(ships._dict) do
        local room = ship:GetRoomByName(name)
        if room then return room end
    end
    
    return nil
end

function ships.Think()
    if #ships._nwdata > table.Count(ships._dict) then
        for _, name in pairs(ships._nwdata) do
            if not ships._dict[name] and LocalPlayer():GetShipName() == name then
                ships._dict[name] = Ship(name)
            end
        end
    end

    for _, ship in pairs(ships._dict) do
        ship:Think()
    end
end
