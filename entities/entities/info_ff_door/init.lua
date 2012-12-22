local ATMOSPHERE_TRANSMIT_RATE = 20.0
local THERMAL_DIFFUSIVITY = 0.019

local OPEN_DISTANCE = 160

ENT.Type = "point"
ENT.Base = "base_point"

ENT.Area = 4
ENT.Rooms = nil

ENT._doorEnts = nil

ENT._open = false
ENT._locked = false
ENT._lastupdate = 0

function ENT:Initialize()
	self.Rooms = {}
end

function ENT:InitPostEntity()
	self._lastupdate = CurTime()
	
	local name = self:GetName()
	local doorName = string.Replace( name, "_info_", "_" )
	
	self._doorEnts = ents.FindByName( doorName )
end

function ENT:AddRoom( room )
	table.insert( self.Rooms, room )
end

function ENT:AcceptInput( name, activator, caller, data )
	if name == "Opened" then
		self._open = true
	elseif name == "Closed" then
		self._open = false
	end
end

function ENT:Open()
	if not self._locked and not self._open then
		for _, ent in ipairs( self._doorEnts ) do
			ent:Fire( "Open", "", 0 )
		end
	end
end

function ENT:Close()
	if not self._locked and self._open then
		for _, ent in ipairs( self._doorEnts ) do
			ent:Fire( "Close", "", 0 )
		end
	end
end

function ENT:Lock()
	self._locked = true
end

function ENT:Unlock()
	self._locked = false
end

function ENT:ToggleLock()
	if self._locked then
		self:Unlock()
	else
		self:Lock()
	end
end

function ENT:LockOpen()
	self:Unlock()
	self:Open()
	self:Lock()
end

function ENT:UnlockClose()
	self:Unlock()
	self:Close()
end

function ENT:Think()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime
	
	if #self.Rooms < 2 then return end
	
	if self:IsOpen() then
		-- TODO: Mass_Flow=2*Door_Area*Mass_Flow_Const*(Pressure1-Pressure2)*((Temp1+Temp2)/2)^(3/2)) / ((Volume1+Volume2)^(1/3))
	
		--[[
		Lawton27: I may be afk a bit tonight so I'll send the final pressure equations. I found pressure changes so fast it's easier & more accurate to just set the pressures equal when a door opens or a pressure changes in an open door. Also whenever there is a pressure equlization I have a temperature equation to represent the movement of different temperature gasses in the equilization.
		Lawton27: New_Pressure_For_Both_Rooms = (Pressure_1*Volume_1 + Pressure_2*Volume_2) / (Volume_1 + Volume_2)
		Lawton27: ^ To be called whenever two rooms of different pressure are connected
		Lawton27: Also the tempurature function should be called with that. It reffers to both the old and new pressures and is different for each room, so should be called twice and before the new pressures are assigned (or temperatures for that matter since they reffer eachother)
		Lawton27: New_Temp_1 = ( Pressure_1*Volume_1*Old_Temp_1 + ( New_Pressure_For_Both_Rooms*(Volume_1 + Volume_2) - Pressure_1*Volume_1)*Old_Temp_2 ) / ( New_Pressure_For_Both_Rooms*(Volume_1 + Volume_2) )
		Lawton27: And obviously just switch the 1s and 2s arround for the equation for room 2
		]]--
	
		-- Temperature transfer
		local roomA = self.Rooms[ 1 ]
		local roomB = self.Rooms[ 2 ]
		if roomA:GetTemperature() < roomB:GetTemperature() then
			roomA = self.Rooms[ 2 ]
			roomB = self.Rooms[ 1 ]
		end
		local delta = 8 * ( roomA:GetTemperature() - roomB:GetTemperature() ) / ( math.pow( roomA.Volume + roomB.Volume, 2 / 3 ) * ( roomA:GetAtmosphere() + roomB:GetAtmosphere() ) ) * self.Area * THERMAL_DIFFUSIVITY * dt
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
		
		if self:IsUnlocked() then
			local shouldClose = true
			local pos = self:GetPos()
			for _, ply in ipairs( player.GetAll() ) do
				if ply:GetPos():Distance( pos ) <= OPEN_DISTANCE then
					shouldClose = false
					break
				end
			end
			
			if shouldClose then
				self:Close()
			end
		end
	elseif self:IsUnlocked() then
		local shouldOpen = false
		local pos = self:GetPos()
		for _, ply in ipairs( player.GetAll() ) do
			if ply:GetPos():Distance( pos ) <= OPEN_DISTANCE then
				shouldOpen = true
				break
			end
		end
		
		if shouldOpen then
			self:Open()
		end
	end
end

function ENT:IsOpen()
	return self._open
end

function ENT:IsClosed()
	return not self._open
end

function ENT:IsLocked()
	return self._locked
end

function ENT:IsUnlocked()
	return not self._locked
end
