ships = {}

ships._dict = {}
ships._nwdata = GetGlobalTable("ships")

function ships.Add(ship)
	ships._dict[ship:GetName()] = ship
end

function ships.Remove(ship)
    ship:Remove()
    ships._dict[ship:GetName()] = nil
end

function ships.GetByName(name)
    local ship = ships._dict[name]
    if not ship then
        ship = Ship(name)
        ships._dict[name] = ship
    end
	return ship
end

function ships.GetRoomByName(name)
    for _, ship in pairs(ships._dict) do
        if ship then
            local room = ship:GetRoomByName(name)
            if room then return room end
        end
    end
    
    return nil
end

function ships.Think()
    local shipname = LocalPlayer():GetShipName()
    if not ships.GetByName(shipname) then
        ships.Add(Ship(shipname))

        for _, name in pairs(ships._nwdata) do
            if name ~= shipname and ships.GetByName(name) then
                ships.Remove(ships.GetByName(name))
            end
        end
    end

    for _, ship in pairs(ships._dict) do
        if ship then ship:Think() end
    end
end
