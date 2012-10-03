local ROOM_UPDATE_FREQ = 1

ships = {}

ships._dict = {}

function ships.FindByName( name )
	return ships._dict[ name ]
end

local _roomIndex = {}
_roomIndex._lastUpdate = 0

_roomIndex._temperature = 0
_roomIndex._oldTemp = 0
_roomIndex._atmosphere = 0
_roomIndex._oldAtmo = 0
_roomIndex._shields = 0
_roomIndex._oldShld = 0

function _roomIndex:GetName()
	return self.Name
end

function _roomIndex:GetStatusLerp()
	return math.Clamp( ( CurTime() - self._lastUpdate ) / ROOM_UPDATE_FREQ, 0, 1 )
end

function _roomIndex:GetTemperature()
	return self._oldTemp + ( self._temperature - self._oldTemp ) * self:GetStatusLerp()
end

function _roomIndex:GetAtmosphere()
	return self._oldAtmo + ( self._atmosphere - self._oldAtmo ) * self:GetStatusLerp()
end

function _roomIndex:GetShields()
	return self._oldShld + ( self._shields - self._oldShld ) * self:GetStatusLerp()
end

net.Receive( "InitShipData", function( len )
	local name = net.ReadString()
	local roomCount = net.ReadInt( 8 )
	
	local ship = {}
	ship.Rooms = {}
	ship._roomlist = {}
	ship.Doors = {}
	ship.Bounds = Bounds()
	
	for rNum = 1, roomCount do
		local room = {}
		setmetatable( room, { __index = _roomIndex } )
		room.Ship = ship
		room.Name = net.ReadString()
		room.Index = net.ReadInt( 8 )
		room.System = sys.Create( net.ReadString(), room )
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
	
		ship._roomlist[ room.Index ] = room
	end
	
	local doorCount = net.ReadInt( 8 )
	for dNum = 1, doorCount do
		local door = {}
		door.x = net.ReadFloat()
		door.y = net.ReadFloat()
		door.angle = net.ReadFloat()
		
		door.Bounds = Bounds()
		local roomai = net.ReadInt( 8 )
		local roombi = net.ReadInt( 8 )
		door.Rooms = { ship._roomlist[ roomai ], ship._roomlist[ roombi ] }
		
		table.insert( door.Rooms[ 1 ].Doors, door )
		table.insert( door.Rooms[ 2 ].Doors, door )
		table.insert( ship.Doors, door )
	end
	
	ships._dict[ name ] = ship
end )

net.Receive( "ShipRoomStates", function( len )
	local timestamp = net.ReadFloat()
	local name = net.ReadString()
	local ship = ships.FindByName( name )
	while true do
		local index = net.ReadInt( 8 )
		if index == 0 then break end
		local room = ship._roomlist[ index ]
		if timestamp > room._lastUpdate then
			room._oldTemp = room._temperature
			room._oldAtmo = room._atmosphere
			room._oldShld = room._shields
			
			room._temperature = net.ReadFloat()
			room._atmosphere = net.ReadFloat()
			room._shields = net.ReadFloat()
			
			room._lastUpdate = timestamp
		end
	end
end )
