if SERVER then AddCSLuaFile("shared.lua") end

local TEMPERATURE_LOSS_RATE = 0.00000382
local DAMAGE_INTERVAL = 1.0

if SERVER then
	util.AddNetworkString("SetPermission")
end

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT._system = nil
ENT._screens = nil
ENT._doors = nil
ENT._bounds = nil

ENT._lastupdate = 0
ENT._lastdamage = 0

ENT._temperature = 298
ENT._airvolume = 1000
ENT._shields = 1

ENT._players = nil

function ENT:GetShipName()
	return self:GetNWString("shipname")
end

function ENT:GetShip()
	return self:GetNWEntity("ship")
end

function ENT:GetIndex()
	return self:GetNWInt("index", 1)
end

function ENT:GetSystemName()
	return self:GetNWString("systemname")
end

function ENT:GetSystem()
	return self._system
end

function ENT:GetVolume()
	return self:GetNWFloat("volume", 1000)
end

function ENT:GetSurfaceArea()
	return self:GetNWFloat("surfacearea", 60)
end

function ENT:GetCorners()
	return self:GetNWTable("corners")
end

function ENT:GetScreens()
	return self._screens
end

function ENT:GetDoorNames()
	return self:GetNWTable("doornames")
end

function ENT:GetDoors()
	return self._doors
end

function ENT:GetBounds()
	return self._bounds
end

if SERVER then
	ENT._doornames = nil

	function ENT:Initialize()
		self._doornames = {}
	end

	function ENT:KeyValue(key, value)
		if key == "ship" then
			self:SetNWString("shipname", tostring(value))
		elseif key == "system" then
			self:SetNWString("systemname", tostring(value))
		elseif key == "volume" then
			self:SetNWFloat("volume", tonumber(value))
			self:SetNWFloat("surfacearea", math.sqrt(self:GetVolume()) * 6)
		elseif string.find(key, "^door%d*") then
			table.insert(self._doornames, tostring(value))
		end
	end
end

function ENT:InitPostEntity()
	self._doors = {}
	self._screens = {}
	self._bounds = Bounds()
	
	if SERVER then
		if not self._doornames then
			MsgN(self:GetName() .. " has no doors!")
		end

		self:SetNWTable("doornames", self._doornames)

		if self:GetShipName() then
			local ship = ships.FindByName(self:GetShipName())
			if ship then
				self:SetNWEntity("ship", ship)
			else
				Error("Room at " .. tostring(self:GetPos()) .. " (" ..
					self:GetName() .. ") has no ship!\n")
				return
			end
		end
	end
	
	for _, name in ipairs(self:GetDoorNames()) do
		local doors = ents.FindByName(name)
		if #doors > 0 then
			local door = doors[1]
			self:GetShip():AddDoor(door)
			door:AddRoom(self)
			self:AddDoor(door)
		end
	end
	
	if self.SystemName == "medical" then
		self._airvolume = self.Volume -- * math.random()
		self._temperature = 600
	elseif self.SystemName == "transporter" then
		self._temperature = 300
		self._airvolume = 0
	else
		self._airvolume = self.Volume -- * math.random()
		self._temperature = 300
	end
	
	if self.SystemName then
		self.System = sys.Create(self.SystemName, self)
	end
	
	self._shields = math.random()
	self._lastupdate = CurTime()

	self._players = {}
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
	return self._temperature * self:GetAtmosphere()
end

function ENT:SetTemperature(temp)
	self._temperature = math.Clamp(temp / self:GetAtmosphere(), 0, 600)
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
		--print(self:Nick() .. " is leaving " .. self._room:GetName())
		self._room:_removePlayer(self)
	end
	--print(self:Nick() .. " is entering " .. room:GetName())
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

net.Receive("SetPermission", function(len, ply)
	local ship = ships.FindByName(net.ReadString())
	local room = ship:GetRoomByIndex(net.ReadInt(8))
	local plyr = net.ReadEntity()
	local perm = net.ReadInt(8)

	if plyr and plyr:IsValid() then
		plyr:SetPermission(room, perm)
	end
end)
