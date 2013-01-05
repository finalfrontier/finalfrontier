local TEMPERATURE_TRANSMIT_RATE = 0.05
local ATMOSPHERE_TRANSMIT_RATE = 20.0

local OPEN_DISTANCE = 160

ENT.Type = "point"
ENT.Base = "base_point"

ENT.Area = 4
ENT.Rooms = nil

ENT.Index = 0

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
	local doorName = string.Replace(name, "_info_", "_")
	
	self._doorEnts = ents.FindByName(doorName)
end

function ENT:AddRoom(room)
	table.insert(self.Rooms, room)
end

function ENT:AcceptInput(name, activator, caller, data)
	if name == "Opened" then
		self._open = true
	elseif name == "Closed" then
		self._open = false
	end
end

function ENT:Open()
	if not self._locked and not self._open then
		for _, ent in ipairs(self._doorEnts) do
			ent:Fire("Open", "", 0)
		end
	end
end

function ENT:Close()
	if not self._locked and self._open then
		for _, ent in ipairs(self._doorEnts) do
			ent:Fire("Close", "", 0)
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
		-- Temperature transfer
		local roomA = self.Rooms[1]
		local roomB = self.Rooms[2]
		if roomA:GetTemperature() < roomB:GetTemperature() then
			roomA = self.Rooms[2]
			roomB = self.Rooms[1]
		end
		local delta = (roomA:GetTemperature() - roomB:GetTemperature()) * self.Area * TEMPERATURE_TRANSMIT_RATE * dt
		if delta > 0 then
			roomA:TransmitTemperature(roomB, delta)
		end
		
		-- Atmosphere transfer
		roomA = self.Rooms[1]
		roomB = self.Rooms[2]
		if roomA:GetAtmosphere() < roomB:GetAtmosphere() then
			roomA = self.Rooms[2]
			roomB = self.Rooms[1]
		end
		delta = (roomA:GetAtmosphere() - roomB:GetAtmosphere()) * self.Area * ATMOSPHERE_TRANSMIT_RATE * dt
		if delta > 0 then
			roomA:TransmitAir(roomB, delta)
		end
		
		if self:IsUnlocked() then
			local shouldClose = true
			local pos = self:GetPos()
			for _, ply in ipairs(player.GetAll()) do
				if ply:GetPos():Distance(pos) <= OPEN_DISTANCE then
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
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetPos():Distance(pos) <= OPEN_DISTANCE then
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
