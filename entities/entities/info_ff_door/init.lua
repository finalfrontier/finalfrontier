local TEMPERATURE_TRANSMIT_RATE = 0.05
local ATMOSPHERE_TRANSMIT_RATE = 20.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT._rooms = nil
ENT._doorEnts = nil

ENT._lastupdate = 0

ENT._nwdata = nil

function ENT:Initialize()
	self._rooms = {}

	if not self._nwdata then
		self._nwdata = {}
		self._nwdata.roomnames = {}
	end

	self._nwdata.name = self:GetName()

	self:_SetArea(4)
end

function ENT:KeyValue(key, value)
	if not self._nwdata then self._nwdata = {} end

	if key == "room1" then
		self:_SetRoomName(1, tostring(value))
	elseif key == "room2" then
		self:_SetRoomName(2, tostring(value))
	end
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
		local x, y = trans:Transform(v.x, v.y)
		self._nwdata.corners[i] = { x = x, y = y }
	end
	self:_UpdateNWData()

	self:_UpdateRooms()

	self:_NextUpdate()
end

function ENT:SetIsPowered(powered)
	self._nwdata.powered = powered
	self:_UpdateNWData()
end

function ENT:IsPowered()
	return self._nwdata.powered or false
end

function ENT:_SetArea(area)
	self._nwdata.area = value
	self:_UpdateNWData()
end

function ENT:GetArea()
	return self._nwdata.area or 4
end

function ENT:SetIndex(index)
	self._nwdata.index = index
	self:_UpdateNWData()
end

function ENT:GetIndex()
	return self._nwdata.index
end

function ENT:_SetRoomName(index, name)
	if not self._nwdata.roomnames then self._nwdata.roomnames = {} end

	if index < 1 or index > 2 then return end

	self._nwdata.roomnames[index] = name
end

function ENT:GetRoomNames()
	return self._nwdata.roomnames
end

function ENT:_UpdateRooms()
	for i = 1, 2 do
		local name = self:GetRoomNames()[i]
		if not name then
			print("Door \"" .. self:GetName() ..
				"\" has a missing room association #" .. tostring(i))
		else
			local rooms = ents.FindByName(name)
			if #rooms > 0 then
				local room = rooms[1]
				room:AddDoor(self)
				self._rooms[i] = room
				room:GetShip():AddDoor(self)
			end
		end
	end
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

function ENT:_NextUpdate()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	return dt
end

function ENT:Think()
	local dt = self:_NextUpdate()
	
	local rooms = self:GetRooms()

	if #rooms < 2 then return end
	
	if self:IsOpen() then	
		-- Temperature transfer
		local roomA = rooms[1]
		local roomB = rooms[2]
		if roomA:GetUnitTemperature() < roomB:GetUnitTemperature() then
			roomA = rooms[2]
			roomB = rooms[1]
		end

		local delta = (roomA:GetUnitTemperature() - roomB:GetUnitTemperature())
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
