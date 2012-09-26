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
