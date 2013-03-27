local TEMPERATURE_LOSS_RATE = 0.00000382
local DAMAGE_INTERVAL = 1.0

ENT.Type = "point"
ENT.Base = "base_point"

ENT.Ship = nil

ENT.System = nil

ENT.Corners = nil
ENT.Screens = nil
ENT.Doors = nil
ENT.Bounds = nil

ENT._lastupdate = 0
ENT._lastdamage = 0

ENT._airvolume = 1000
ENT._shields = 1

ENT._players = nil

ENT._nwdata = nil

function ENT:SetShipName(name)
	self._nwdata.shipname = name
	self:UpdateNWData()
end

function ENT:GetShipName()
	return self._nwdata.shipname
end

function ENT:SetSystemName(name)
	self._nwdata.systemname = name
	self:UpdateNWData()
end

function ENT:GetSystemName()
	return self._nwdata.systemname
end

function ENT:Initialize()
	self.Corners = {}
	self.Doors = {}
	self.Screens = {}
	self.Bounds = Bounds()

	self._players = {}
	self._nwdata = {}
	self._nwdata.doornames = {}
end

function ENT:KeyValue(key, value)
	if key == "ship" then
		self:SetShipName(tostring(value))
	elseif key == "system" then
		self:SetSystemName(tostring(value))
	elseif key == "volume" then
		self:SetVolume(tonumber(value))
		self:SetSurfaceArea(math.sqrt(self.Volume) * 6)
	elseif string.find(key, "^door%d*") then
		self:AddDoorName(tostring(value))
	end
end

function ENT:InitPostEntity()	
	if not self.DoorNames then
		MsgN(self:GetName() .. " has no doors!")
	end
	
	self.DoorNames = self.DoorNames or {}
	if self.ShipName then
		self.Ship = ships.FindByName(self.ShipName)
		if self.Ship then
			self.Ship:AddRoom(self)
		end
	end
	
	if not self.Ship then
		Error("Room at " .. tostring(self:GetPos()) .. " (" .. self:GetName() .. ") has no ship!\n")
		return
	end
	
	for _, name in ipairs(self.DoorNames) do
		local doors = ents.FindByName(name)
		if #doors > 0 then
			local door = doors[1]
			self.Ship:AddDoor(door)
			door:AddRoom(self)
			self:AddDoor(door)			
		end
	end
	
	if self.SystemName == "medical" then
		self._airvolume = self.Volume -- * math.random()
		self:SetTemperature(600)
	elseif self.SystemName == "transporter" then
		self:SetTemperature(300)
		self._airvolume = 0
	else
		self:SetTemperature(300)
		self._airvolume = self.Volume -- * math.random()
	end
	
	if self.SystemName then
		self.System = sys.Create(self.SystemName, self)
	end
	
	self._shields = math.random()
	self._lastupdate = CurTime()

	self:UpdateNWData()
end

local DROWN_SOUNDS = {
	"npc/combine_soldier/pain1.wav",
	"npc/combine_soldier/pain2.wav",
	"npc/combine_soldier/pain3.wav"
}

function ENT:Think()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	if self.System then self.System:Think(dt) end
	
	self._temperature = self._temperature * (1 - TEMPERATURE_LOSS_RATE * self.SurfaceArea * dt)

	local min = Vector(self.Bounds.l, self.Bounds.t, -65536)
	local max = Vector(self.Bounds.r, self.Bounds.b, 65536)

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

function ENT:AddCorner(index, x, y)
	self.Corners[index] = { x = x, y = y }
	self.Bounds:AddPoint(x, y)
	self.Ship.Bounds:AddPoint(x, y)
end

function ENT:AddDoor(door)
	for i, other in ipairs(self.Doors) do
		if other.Index > door.Index then
			table.insert(self.Doors, i, door)
			return
		end
	end
	table.insert(self.Doors, door)
end

function ENT:AddScreen(screen)
	table.insert(self.Screens, screen)
end

function ENT:GetTemperature()
	return self._nwdata.temperature * self:GetAtmosphere()
end

function ENT:SetTemperature(temp)
	self._nwdata.temperature = math.Clamp(temp / self:GetAtmosphere(), 0, 600)
end

function ENT:GetAirVolume()
	return self._airvolume
end

function ENT:GetAtmosphere()
	return self._airvolume / self.Volume
end

function ENT:GetShields()
	return self._shields
end

function ENT:TransmitTemperature(room, delta)
	if delta < 0 then room:TransmitTemperature(self, delta) return end

	if delta > self._temperature then delta = self._temperature end
	
	self._temperature = self._temperature - delta
	room._temperature = room._temperature + delta
end

function ENT:TransmitAir(room, delta)
	if delta < 0 then room:TransmitAir(self, delta) return end

	if delta > self._airvolume then delta = self._airvolume end
	
	self._airvolume = self._airvolume - delta
	room._airvolume = room._airvolume + delta
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
		self._room:_removePlayer(self)
	end
	room:_addPlayer(self)
	self._room = room
	self:SetNWInt("room", room.Index)
end

function ply_mt:GetRoom()
	return self._room
end

function ENT:_addPlayer(ply)
	if not table.HasValue(self._players, ply) then
		table.insert(self._players, ply)
	end
end

function ENT:_removePlayer(ply)
	if table.HasValue(self._players, ply) then
		table.remove(self._players, table.KeyFromValue(self._players, ply))
	end
end

function ENT:GetPlayers()
	return self._players
end

function ENT:IsPointInside(x, y)
	return self.Bounds:IsPointInside(x, y)
end

function ENT:UpdateNWData()
	SetGlobalTable(self:GetName(), self._nwdata)
end
