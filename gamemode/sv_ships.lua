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

if not ships then
    ships = {}

    ships._dict = {}
    ships._nwdata = NetworkTable("ships")
end

function ships.Add(ship)
    local name = ship:GetName()
    if not name or ships._dict[name] then return end
    
    ships._dict[name] = ship
    table.insert(ships._nwdata, name)
    ships._nwdata:Update()

    team.Add(ship)

    local x, y = ship:GetCoordinates()
    local sector = universe:GetSector(x, y)
    MsgN("Ship added in sector " .. sector:GetSectorName()
        .. " : [" .. x .. ", " .. y .. "] (" .. name .. ")")
end

function ships.GetAll()
    return ships._dict
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

function ships.InitPostEntity()
    local classOrder = {
        "info_ff_universe",
        "info_ff_ship",
        "info_ff_room",
        "info_ff_roomcorner",
        "info_ff_roomdetail",
        "info_ff_transtarget",
        "info_ff_damageeffect",
        "info_ff_door",
        "info_ff_screen",
        "info_ff_moduleslot"
    }

    for _1, class in ipairs(classOrder) do
        for _2, ent in ipairs(ents.FindByClass(class)) do
            ent:InitPostEntity()
        end
    end
end

function ships.FindCurrentShip(ply)
    local pos = ply:GetPos()
    for _, ship in pairs(ships._dict) do
        if ship:IsPointInside(pos.x, pos.y) then return ship end
    end
    return nil
end
