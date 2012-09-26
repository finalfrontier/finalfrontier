Ships = {}

Ships._dict = {}

function Ships.Add( ship )
	local name = ship:GetName()
	if not name then return end
	
	Ships._dict[ name ] = ship
	MsgN( "Ship added at " .. tostring( ship:GetPos() ) .. " (" .. name .. ")" )
end

function Ships.FindByName( name )
	return Ships._dict[ name ]
end

function Ships.InitPostEntity()
	local classOrder = { "info_ff_ship", "func_ff_room", "info_ff_door", "info_ff_screen" }

	for _1, class in ipairs( classOrder ) do
		for _2, ent in ipairs( ents.FindByClass( class ) ) do
			ent:InitPostEntity()
		end
	end
end
