local TEMPERATURE_LOSS_RATE = 0.00000382
local DAMAGE_INTERVAL = 1.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT._ship = nil
ENT._screens = nil
ENT._system = nil
ENT._doors = nil
ENT._bounds = nil

ENT._lastupdate = 0
ENT._lastdamage = 0

ENT._players = nil

ENT._nwdata = nil

function ENT:Initialize()
	self._screens = {}
	self._doors = {}
	self._bounds = Bounds()

	self._players = {}

	if not self._nwdata then
		self._nwdata = {}
		self._nwdata.doornames = {}
		self._nwdata.corners = {}
	end

	self:SetIndex(0)
end

function ENT:KeyValue(key, value)
	if not self._nwdata then self._nwdata = {} end

	if key == "ship" then
		self:_SetShipName(tostring(value))
	elseif key == "system" then
		self:_SetSystemName(tostring(value))
	elseif key == "volume" then
		self:_SetVolume(tonumber(value))
		self:_SetSurfaceArea(math.sqrt(self:GetVolume()) * 6)
	elseif string.find(key, "^door%d*") then
		self:_AddDoorName(tostring(value))
	end
end

function ENT:InitPostEntity()
	if #self:GetDoorNames() == 0 then
		MsgN(self:GetName() .. " has no doors!")
	end
	
	self:_UpdateShip()

	if not self:GetShip() then return end

	self:_UpdateDoors()
	self:_UpdateSystem()

	self:SetAirVolume(self:GetVolume())
	self:SetTemperature(300)
	
	local sysName = self:GetSystemName()
	if sysName == "medical" then
		self:SetTemperature(600)
	elseif sysName == "transporter" then
		self:SetAirVolume(0)
	end
		
	self:SetShields(math.random())

	self:_NextUpdate()
end

local DROWN_SOUNDS = {
	"npc/combine_soldier/pain1.wav",
	"npc/combine_soldier/pain2.wav",
	"npc/combine_soldier/pain3.wav"
}

function ENT:_NextUpdate()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	return dt
end

function ENT:Think()
	local dt = self:_NextUpdate()

	if self:HasSystem() then self:GetSystem():Think(dt) end
	
	self:SetTemperature(self:GetTemperature() * (1 - TEMPERATURE_LOSS_RATE
		* self:GetSurfaceArea() * dt))

	local bounds = self:GetBounds()
	local min = Vector(bounds.l, bounds.t, -65536)
	local max = Vector(bounds.r, bounds.b, 65536)

	for _, ent in pairs(ents.FindInBox(min, max)) do
		local pos = ent:GetPos()
		if ent:IsPlayer() and self:IsPointInside(pos.x, pos.y)
			and ent:GetRoom() ~= self then
			ent:SetRoom(self)
		end
	end

	if CurTime() - self._lastdamage > DAMAGE_INTERVAL then
		local dmg = nil
		local sounds = nil

		if self:GetTemperature() > 350 then
			dmg = DamageInfo()
			dmg:SetDamageType(DMG_BURN)
			dmg:SetDamage(math.min(math.ceil((self:GetTemperature() - 350) / 25), 10))
		elseif self:GetAtmosphere() < 0.75 then
			dmg = DamageInfo()
			dmg:SetDamageType(DMG_POISON)
			dmg:SetDamage(math.min(math.ceil((0.75 - self:GetAtmosphere()) * 10), 10))
			sounds = DROWN_SOUNDS
		end

		if dmg then
			for _, ply in pairs(self._players) do
				if ply and ply:IsValid() and ply:Alive() then
					ply:TakeDamageInfo(dmg)
					if sounds then
						ply:EmitSound(table.Random(sounds), SNDLVL_IDLE, 100)
					end
				end
			end
		end
		self._lastdamage = CurTime()
	end
end

function ENT:SetIndex(index)
	self._nwdata.index = index
	self:_UpdateNWData()
end

function ENT:GetIndex()
	return self._nwdata.index
end

function ENT:_SetShipName(name)
	self._nwdata.shipname = name
	self:_UpdateNWData()
end

function ENT:GetShipName()
	return self._nwdata.shipname
end

function ENT:_UpdateShip()
	local name = self:GetShipName()
	if name then
		self._ship = ships.GetByName(name)
		if self._ship then
			self._ship:AddRoom(self)
		end
	else
		Error("Room at " .. tostring(self:GetPos()) .. " (" .. self:GetName()
			.. ") has no ship!\n")
	end
end

function ENT:GetShip()
	return self._ship
end

function ENT:_SetSystemName(name)
	self._nwdata.systemname = name
	self:_UpdateNWData()
end

function ENT:GetSystemName()
	return self._nwdata.systemname
end

function ENT:_UpdateSystem()
	local name = self:GetSystemName()
	if name then
		self._system = sys.Create(name, self)
	end
end

function ENT:HasSystem()
	return self._system ~= nil
end

function ENT:GetSystem()
	return self._system
end

function ENT:_SetVolume(value)
	self._nwdata.volume = value
	self:_UpdateNWData()
end

function ENT:GetVolume()
	return self._nwdata.volume or 0
end

function ENT:_SetSurfaceArea(value)
	self._nwdata.surfacearea = value
	self:_UpdateNWData()
end

function ENT:GetSurfaceArea()
	return self._nwdata.surfacearea or 0
end

function ENT:GetBounds()
	return self._bounds
end

function ENT:AddCorner(index, x, y)
	if not self._nwdata.corners then self._nwdata.corners = {} end

	self._nwdata.corners[index] = { x = x, y = y }
	self:GetBounds():AddPoint(x, y)
	self:GetShip():GetBounds():AddPoint(x, y)
	self:_UpdateNWData()
end

function ENT:GetCorners()
	return self._nwdata.corners
end

function ENT:_AddDoorName(name)
	if not self._nwdata.doornames then self._nwdata.doornames = {} end
	if self._nwdata.doornames[name] then return end

	table.insert(self._nwdata.doornames, name)
	self:_UpdateNWData()
end

function ENT:GetDoorNames()
	return self._nwdata.doornames
end

function ENT:_AddDoor(door)
	self._doors[door:GetIndex()] = door -- may not work
end

function ENT:_UpdateDoors()
	for _, name in ipairs(self:GetDoorNames()) do
		local doors = ents.FindByName(name)
		if #doors > 0 then
			local door = doors[1]
			self:GetShip():AddDoor(door)
			door:AddRoom(self)
			self:_AddDoor(door)
		end
	end
end

function ENT:GetDoors()
	return self._doors
end

function ENT:AddScreen(screen)
	table.insert(self._screens, screen)
end

function ENT:GetScreens()
	return self._screens
end

function ENT:SetTemperature(temp)
	self._nwdata.temperature = math.Clamp(temp / self:GetAtmosphere(), 0, 600)
	self:_UpdateNWData()
end

function ENT:GetTemperature()
	return self._nwdata.temperature * self:GetAtmosphere()
end

function ENT:SetAirVolume(volume)
	self._nwdata.airvolume = math.Clamp(volume, 0, self:GetVolume())
	self:_UpdateNWData()
end

function ENT:GetAirVolume()
	return self._nwdata.airvolume
end

function ENT:SetAtmosphere(atmosphere)
	self:SetAirVolume(self:GetVolume() * atmosphere)
end

function ENT:GetAtmosphere()
	return self:GetAirVolume() / self:GetVolume()
end

function ENT:SetShields(shields)
	self._nwdata.shields = math.Clamp(shields, 0, 1)
	self:_UpdateNWData()
end

function ENT:GetShields()
	return self._nwdata.shields
end

function ENT:TransmitTemperature(room, delta)
	if delta < 0 then room:TransmitTemperature(self, delta) return end

	delta = math.min(delta, self:GetTemperature())
	
	self:SetTemperature(self:GetTemperature() - delta)
	room:SetTemperature(room:GetTemperature() + delta)
end

function ENT:TransmitAir(room, delta)
	if delta < 0 then room:TransmitAir(self, delta) return end

	delta = math.min(delta, self:GetAirVolume())
	
	self:SetAirVolume(self._airvolume - delta)
	room:SetAirVolume(room._airvolume + delta)
end

function ENT:GetPermissionsName()
	return "p_" .. self.ShipName .. "_" .. self.Index
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetPermission(room)
	return self:GetNWInt(room:GetPermissionsName(), 0)
end

function ply_mt:HasPermission(room, perm)
	return self:GetPermission(room) >= perm
end

function ply_mt:SetPermission(room, perm)
	self:SetNWInt(room:GetPermissionsName(), perm)
end

function ply_mt:HasDoorPermission(door)
	return self:HasPermission(door.Rooms[1], permission.ACCESS)
		or self:HasPermission(door.Rooms[2], permission.ACCESS)
end

function ply_mt:SetRoom(room)
	if self._room == room then return end
	if self._room then
		self._room:_RemovePlayer(self)
	end
	room:_AddPlayer(self)
	self._room = room
	self:SetNWInt("room", room.Index)
end

function ply_mt:GetRoom()
	return self._room
end

function ENT:_AddPlayer(ply)
	if not table.HasValue(self._players, ply) then
		table.insert(self._players, ply)
	end
end

function ENT:_RemovePlayer(ply)
	if table.HasValue(self._players, ply) then
		table.remove(self._players, table.KeyFromValue(self._players, ply))
	end
end

function ENT:GetPlayers()
	return self._players
end

function ENT:IsPointInside(x, y)
	return self:GetBounds():IsPointInside(x, y)
end

function ENT:_UpdateNWData()
	SetGlobalTable(self:GetName(), self._nwdata)
end
