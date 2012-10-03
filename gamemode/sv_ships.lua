local ROOM_UPDATE_FREQ = 1

ships = {}

ships._dict = {}

function ships.Add( ship )
	local name = ship:GetName()
	if not name then return end
	
	ships._dict[ name ] = ship
	MsgN( "Ship added at " .. tostring( ship:GetPos() ) .. " (" .. name .. ")" )
end

function ships.FindByName( name )
	return ships._dict[ name ]
end

function ships.FindRoomByName( name )
	for _, ship in pairs( ships._dict ) do
		if ship.Rooms[ name ] then return ship.Rooms[ name ] end
	end
	
	return nil
end

function ships.InitPostEntity()
	local classOrder = { "info_ff_ship", "func_ff_room", "info_ff_roomcorner", "info_ff_door", "info_ff_screen" }

	for _1, class in ipairs( classOrder ) do
		for _2, ent in ipairs( ents.FindByClass( class ) ) do
			ent:InitPostEntity()
		end
	end
end

function ships.SendInitShipsData( ply )
	for _, ship in pairs( ships._dict ) do
		ship:SendInitShipData( ply )
	end
end

function ships.SendRoomStatesUpdate( ply )
	local curTime = CurTime()
	if ( curTime - ply:GetNWFloat( "lastRoomUpdate" ) ) > ROOM_UPDATE_FREQ then
		ply:SetNWFloat( "lastRoomUpdate", curTime )
		
		for _, ship in pairs( ships._dict ) do
			ship:SendShipRoomStates( ply )
		end
	end
end
