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

ENT._nwdata = nil

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
		self._nwdata.open = true
		self:UpdateNWData()
	elseif name == "Closed" then
		self._open = false
		self._nwdata.open = false
		self:UpdateNWData()
	end
end

function ENT:Open()
	if self:IsUnlocked() and self:IsClosed() then
		for _, ent in ipairs(self._doorEnts) do
			ent:Fire("Open", "", 0)
		end
	end
end

function ENT:Close()
	if self:IsUnlocked() and self:IsOpen() then
		for _, ent in ipairs(self._doorEnts) do
			ent:Fire("Close", "", 0)
		end
	end
end

function ENT:Lock()
	if self:IsUnlocked() then
		self._locked = true
		self._nwdata.locked = true
		self:UpdateNWData()
		self:EmitSound("doors/door_metal_large_close2.wav", SNDLVL_STATIC, 100)
	end
end

function ENT:Unlock()
	if self:IsLocked() then
		self._locked = false
		self._nwdata.locked = false
		self:UpdateNWData()
		self:EmitSound("doors/door_metal_large_open1.wav", SNDLVL_STATIC, 100)
	end
end

function ENT:ToggleLock()
	if self:IsLocked() then
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

function ENT:UpdateNWData()
	SetGlobalTable(self:GetName(), self._nwdata)
end
