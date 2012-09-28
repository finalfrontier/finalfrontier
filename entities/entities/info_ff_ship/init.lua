ENT.Type = "point"
ENT.Base = "base_point"

ENT.BaseHullHealth = 1
ENT.Rooms = nil

function ENT:KeyValue( key, value )
	if key == "hullhealth" then
		self.BaseHullHealth = tonumber( value )
	end
end

function ENT:Initialize()
	self.Rooms = {}
end

function ENT:InitPostEntity()
	Ships.Add( self )
end

function ENT:AddRoom( room )
	local name = room:GetName()
	if not name then return end

	self.Rooms[ name ] = room
end

util.AddNetworkString( "ShipData" )

function ENT:SendShipData( ply )
	net.Start( "ShipData" )
		net.WriteString( self:GetName() )
		net.WriteInt( table.Count( self.Rooms ), 8 )
		
		for name, room in pairs( self.Rooms ) do
			net.WriteString( name )
			net.WriteInt( table.Count( room.Corners ), 8 )
			for i, v in pairs( room.Corners ) do
				net.WriteInt( i, 8 )
				net.WriteFloat( v.x )
				net.WriteFloat( v.y )
			end
		end
	net.Send( ply )
end
