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

function ships.GetAll()
    return ships._dict
end

function ships.GetByName(name)
    local ship = ships._dict[name]
    if not ship and name and string.len(name) > 0 then
        print("Loading new ship " .. name)
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
