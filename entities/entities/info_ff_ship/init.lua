ENT.Type = "point"
ENT.Base = "base_point"

ENT.BaseHullHealth = 1
ENT.Rooms = nil

ENT.Bounds = nil

function ENT:KeyValue( key, value )
	if key == "hullhealth" then
		self.BaseHullHealth = tonumber( value )
	end
end

function ENT:Initialize()
	self.Rooms = {}
	self.Bounds = Bounds()
end

function ENT:InitPostEntity()
	Ships.Add( self )
end

function ENT:AddRoom( room )
	local name = room:GetName()
	if not name then return end

	self.Rooms[ name ] = room
	self.Bounds:AddBounds( room.Bounds )
end

util.AddNetworkString( "ShipData" )

function ENT:SendShipData( ply )
	net.Start( "ShipData" )
		net.WriteString( self:GetName() )		
		net.WriteInt( table.Count( self.Rooms ), 8 )
		
		local doors = {}
		
		for name, room in pairs( self.Rooms ) do
			net.WriteString( name )
			net.WriteInt( table.Count( room.Corners ), 8 )
			for i, v in pairs( room.Corners ) do
				net.WriteInt( i, 8 )
				net.WriteFloat( v.x )
				net.WriteFloat( v.y )
			end
			
			for _, door in ipairs( room.Doors ) do
				if not table.HasValue( doors, door ) then
					table.insert( doors, door )
				end
			end
		end
		
		--[[
		net.WriteInt( #doors, 8 )
		for _, door in ipairs( doors ) do
			local pos = door:GetPos()
			net.WriteFloat( pos.x )
			net.WriteFloat( pos.y )
			net.WriteFloat( door:GetAngles().z )
		end
		]]--
	net.Send( ply )
end
