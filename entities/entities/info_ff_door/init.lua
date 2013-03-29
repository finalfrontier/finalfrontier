local TEMPERATURE_TRANSMIT_RATE = 0.05
local ATMOSPHERE_TRANSMIT_RATE = 20.0

local OPEN_DISTANCE = 160

ENT.Type = "point"
ENT.Base = "base_point"

ENT._rooms = nil
ENT._doorEnts = nil

ENT._lastupdate = 0

ENT._nwdata = nil

function ENT:Initialize()
	self._rooms = {}
	self._nwdata = {}

	self:_SetArea(4)
end

function ENT:InitPostEntity()
	local name = self:GetName()
	local doorName = string.Replace(name, "_info_", "_")

	self._doorEnts = ents.FindByName(doorName)

	local coords = {
		{ x = -32, y = -64 },
		{ x = -32, y =  64 },
		{ x =  32, y =  64 },
		{ x =  32, y = -64 }
	}

	local trans = Transform2D()
	trans:Rotate(self:GetAngles().y * math.pi / 180)
	local pos = self:GetPos()
	trans:Translate(pos.x, pos.y)
	
	self._nwdata.corners = {}
	for i, v in ipairs(coords) do
		self._nwdata.corners[i] = trans:Transform(v.x, v.y)
	end
	self:_UpdateNWData()

	self:NextUpdate()
end

function ENT:_SetArea(area)
	self._nwdata.area = value
	self:_UpdateNWData()
end

function ENT:GetArea()
	return self._nwdata.area
end

function ENT:SetIndex(index)
	self._nwdata.index = index
	self:_UpdateNWData()
end

function ENT:GetIndex()
	return self._nwdata.index
end

function ENT:AddRoom(room)
	table.insert(self._rooms, room)
end

function ENT:GetRooms()
	return self._rooms
end

function ENT:AcceptInput(name, activator, caller, data)
	if name == "Opened" then
		self._nwdata.open = true
		self:_UpdateNWData()
	elseif name == "Closed" then
		self._nwdata.open = false
		self:_UpdateNWData()
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
		self._nwdata.locked = true
		self:_UpdateNWData()
		self:EmitSound("doors/door_metal_large_close2.wav", SNDLVL_STATIC, 100)
	end
end

function ENT:Unlock()
	if self:IsLocked() then
		self._nwdata.locked = false
		self:_UpdateNWData()
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

function ENT:NextUpdate()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	return dt
end

function ENT:Think()
	local dt = self:NextUpdate()
	
	local rooms = self:GetRooms()

	if #rooms < 2 then return end
	
	if self:IsOpen() then	
		-- Temperature transfer
		local roomA = rooms[1]
		local roomB = rooms[2]
		if roomA:GetTemperature() < roomB:GetTemperature() then
			roomA = rooms[2]
			roomB = rooms[1]
		end

		local delta = (roomA:GetTemperature() - roomB:GetTemperature())
			* self:GetArea() * TEMPERATURE_TRANSMIT_RATE * dt

		if delta > 0 then
			roomA:TransmitTemperature(roomB, delta)
		end
		
		-- Atmosphere transfer
		roomA = rooms[1]
		roomB = rooms[2]
		if roomA:GetAtmosphere() < roomB:GetAtmosphere() then
			roomA = rooms[2]
			roomB = rooms[1]
		end

		delta = (roomA:GetAtmosphere() - roomB:GetAtmosphere())
			* self:GetArea() * ATMOSPHERE_TRANSMIT_RATE * dt

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
	return self._nwdata.open
end

function ENT:IsClosed()
	return not self._nwdata.open
end

function ENT:IsLocked()
	return self._nwdata.locked
end

function ENT:IsUnlocked()
	return not self._nwdata.locked
end

function ENT:_UpdateNWData()
	SetGlobalTable(self:GetName(), self._nwdata)
end
