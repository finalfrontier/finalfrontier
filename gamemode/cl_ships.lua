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
	ship.Bounds = Bounds()
	
	for rNum = 1, roomCount do
		local room = {}
		room.Name = net.ReadString()
		room.Bounds = Bounds()
		room.Doors = {}
		
		room.Corners = {}
		local cornerCount = net.ReadInt( 8 )
		for cNum = 1, cornerCount do
			local index = net.ReadInt( 8 )
			local pos = { x = net.ReadFloat(), y = net.ReadFloat() }
			
			room.Corners[ index ] = pos
			room.Bounds:AddPoint( pos.x, pos.y )
		end
		
		room.ConvexPolys = FindConvexPolygons( room.Corners )
		
		ship.Rooms[ room.Name ] = room
		ship.Bounds:AddBounds( room.Bounds )
	end
	
	Ships._dict[ name ] = ship
end )
