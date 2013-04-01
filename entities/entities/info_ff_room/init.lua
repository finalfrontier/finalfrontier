local TEMPERATURE_LOSS_RATE = 0.00000382
local DAMAGE_INTERVAL = 1.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT._ship = nil
ENT._screens = nil
ENT._system = nil
ENT._doorlist = nil
ENT._bounds = nil
ENT._details = nil
ENT._detailindices = nil

ENT._airvolume = 0
ENT._temperature = 0
ENT._shields = 0

ENT._lastupdate = 0
ENT._lastdamage = 0

ENT._players = nil

ENT._nwdata = nil

local function ShouldSync(a, b, delta)
	return math.abs(a - b) >= delta
end

function ENT:Initialize()
	self._screens = {}
	self._doorlist = {}
	self._bounds = Bounds()
	self._details = {}
	self._detailindices = {}

	self._players = {}

	if not self._nwdata then
		self._nwdata = {}
		self._nwdata.corners = {}
	end

	if not self._nwdata.corners then self._nwdata.corners = {} end
	if not self._nwdata.details then self._nwdata.details = {} end

	self._nwdata.temperature = 0
	self._nwdata.airvolume = 0
	self._nwdata.shields = 0
	self._nwdata.name = self:GetName()

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
	end
end

function ENT:InitPostEntity()	
	self:_UpdateShip()

	if not self:GetShip() then return end

	self:_UpdateSystem()

	self:SetAirVolume(self:GetVolume())
	self:SetUnitTemperature(300)
	
	local sysName = self:GetSystemName()
	if sysName == "medical" then
		self:SetUnitTemperature(600)
	elseif sysName == "piloting" then
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
	
	self:SetUnitTemperature(self:GetUnitTemperature() *
		(1 - TEMPERATURE_LOSS_RATE * self:GetSurfaceArea() * dt))

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
			dmg:SetDamageType(DMG_ACID)
			dmg:SetDamage(math.min(math.ceil((0.75 - self:GetAtmosphere()) * 10), 10))
			sounds = DROWN_SOUNDS
		end

		if dmg then
			dmg:SetAttacker(self)
			dmg:SetInflictor(self)
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

function ENT:_GetDetailIndex(name)
	if not self._detailindices[name] then
		local index = table.Count(self._detailindices) + 1
		self._detailindices[name] = index
		self._details[index] = { x = 0, y = 0 }
		return index
	end

	return self._detailindices[name]
end

function ENT:AddDetail(name, x, y, nextnames)
	if not self._nwdata.details then self._nwdata.details = {} end

	local index = self:_GetDetailIndex(name)
	self._details[index].x = x
	self._details[index].y = y

	for _, v in pairs(nextnames) do
		local otherIndex = self:_GetDetailIndex(v)
		table.insert(self._nwdata.details, {
			a = self._details[index], b = self._details[otherIndex]
		} )
	end

	self:_UpdateNWData()
end

function ENT:GetDetails()
	return self._nwdata.details
end

function ENT:AddDoor(door)
	if table.HasValue(self._doorlist, door) then return end

	table.insert(self._doorlist, door)
end

function ENT:GetDoors()
	return self._doorlist
end

function ENT:AddScreen(screen)
	table.insert(self._screens, screen)
end

function ENT:GetScreens()
	return self._screens
end

function ENT:SetUnitTemperature(temp)
	self._temperature = math.Clamp(temp, 0, 600)

	if ShouldSync(self._temperature, self._nwdata.temperature, 6) then
		self._nwdata.temperature = self._temperature
		self:_UpdateNWData()
	end
end

function ENT:GetUnitTemperature()
	return self._temperature
end

function ENT:GetTemperature()
	return self:GetUnitTemperature() * self:GetAtmosphere()
end

function ENT:SetAirVolume(volume)
	self._airvolume = math.Clamp(volume, 0, self:GetVolume())

	if ShouldSync(self._airvolume, self._nwdata.airvolume, self:GetVolume() / 100) then
		self._nwdata.airvolume = self._airvolume
		self:_UpdateNWData()
	end
end

function ENT:GetAirVolume()
	return self._airvolume or 0
end

function ENT:SetAtmosphere(atmosphere)
	self:SetAirVolume(self:GetVolume() * atmosphere)
end

function ENT:GetAtmosphere()
	return self:GetAirVolume() / self:GetVolume()
end

function ENT:SetShields(shields)
	self._shields = math.Clamp(shields, 0, 1)

	if ShouldSync(self._shields, self._nwdata.shields, 1 / 100) then
		self._nwdata.shields = self._shields
		self:_UpdateNWData()
	end
end

function ENT:GetShields()
	return self._nwdata.shields
end

function ENT:TransmitTemperature(room, delta)
	if delta < 0 then room:TransmitTemperature(self, delta) return end

	delta = math.min(delta, self:GetUnitTemperature())
	
	self:SetUnitTemperature(self:GetUnitTemperature() - delta)
	room:SetUnitTemperature(room:GetUnitTemperature() + delta)
end

function ENT:TransmitAir(room, delta)
	if delta < 0 then room:TransmitAir(self, delta) return end

	delta = math.min(delta, self:GetAirVolume())
	
	self:SetAirVolume(self:GetAirVolume() - delta)
	room:SetAirVolume(room:GetAirVolume() + delta)
end

function ENT:GetPermissionsName()
	return "p_" .. self:GetShipName() .. "_" .. self:GetIndex()
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
	return self:HasPermission(door:GetRooms()[1], permission.ACCESS)
		or self:HasPermission(door:GetRooms()[2], permission.ACCESS)
end

function ply_mt:SetRoom(room)
	if self._room == room then return end
	if self._room then
		self._room:_RemovePlayer(self)
	end
	room:_AddPlayer(self)
	self._room = room
	self:SetNWInt("room", room:GetIndex())
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
