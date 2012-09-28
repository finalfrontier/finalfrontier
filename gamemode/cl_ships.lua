Ships = {}

Ships._dict = {}

function Ships.FindByName( name )
	return Ships._dict[ name ]
end

net.Receive( "ShipData", function( len )
	local name = net.ReadString()
	local roomCount = net.ReadInt( 8 )
	
	local ship = {}
	ship.Rooms = {}
	
	for rNum = 1, roomCount do
		local roomName = net.ReadString()
		local cornerCount = net.ReadInt( 8 )
		
		ship.Rooms[ roomName ] = {}
		ship.Rooms[ roomName ].Corners = {}
		
		for cNum = 1, cornerCount do
			local index = net.ReadInt( 8 )
			local pos = { x = net.ReadFloat(), y = net.ReadFloat() }
			
			ship.Rooms[ roomName ].Corners[ index ] = pos
		end
	end
	
	Ships._dict[ name ] = ship
end )
