local TEMPERATURE_TRANSMIT_RATE = 0.05
local ATMOSPHERE_TRANSMIT_RATE = 20.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT.Area = 4
ENT.Rooms = nil

ENT._open = false
ENT._lastupdate = 0

function ENT:Initialize()
	self.Rooms = {}
end

function ENT:InitPostEntity()
	self._lastupdate = CurTime()
end

function ENT:AddRoom( room )
	table.insert( self.Rooms, room )
end

function ENT:AcceptInput( name, activator, caller, data )
	if name == "Open" then
		self._open = true
	elseif name == "Close" then
		self._open = false
	end
end

function ENT:Think()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime
	
	if #self.Rooms < 2 then return end
	
	if self:IsOpen() then
		-- Temperature transfer
		local roomA = self.Rooms[ 1 ]
		local roomB = self.Rooms[ 2 ]
		if roomA:GetTemperature() < roomB:GetTemperature() then
			roomA = self.Rooms[ 2 ]
			roomB = self.Rooms[ 1 ]
		end
		local delta = ( roomA:GetTemperature() - roomB:GetTemperature() ) * self.Area * TEMPERATURE_TRANSMIT_RATE * dt
		if delta > 0 then
			roomA:TransmitTemperature( roomB, delta )
		end
		
		-- Atmosphere transfer
		roomA = self.Rooms[ 1 ]
		roomB = self.Rooms[ 2 ]
		if roomA:GetAtmosphere() < roomB:GetAtmosphere() then
			roomA = self.Rooms[ 2 ]
			roomB = self.Rooms[ 1 ]
		end
		delta = ( roomA:GetAtmosphere() - roomB:GetAtmosphere() ) * self.Area * ATMOSPHERE_TRANSMIT_RATE * dt
		if delta > 0 then
			roomA:TransmitAir( roomB, delta )
		end
	end
end

function ENT:IsOpen()
	return self._open
end
