if SERVER then AddCSLuaFile("sh_ships.lua") end

local ROOM_UPDATE_FREQ = 1

ships = {}

ships._dict = {}

function ships.Add(ship)
	local name = ship:GetName()
	if not name then return end
	
	ships._dict[name] = ship
	MsgN("Ship added at " .. tostring(ship:GetPos()) .. " (" .. name .. ")")
end

function ships.FindByName(name)
	return ships._dict[name]
end

function ships.FindRoomByName(name)
	for _, ship in pairs(ships._dict) do
		if ship.Rooms[name] then return ship.Rooms[name] end
	end
	
	return nil
end

function ships.InitPostEntity()
	local classOrder = {
		"info_ff_ship",
		"info_ff_room",
		"info_ff_roomcorner",
		"info_ff_door",
		"info_ff_screen"
	}

	for _1, class in ipairs(classOrder) do
		for _2, ent in ipairs(ents.FindByClass(class)) do
			if ent.InitPostEntity then
				ent:InitPostEntity()
			end
		end
	end
end

if SERVER then
	function ships.FindCurrentShip(ply)
		local pos = ply:GetPos()
		for _, ship in pairs(ships._dict) do
			if ship:IsPointInside(pos.x, pos.y) then return ship end
		end
		return nil
	end
end
