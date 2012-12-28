local TEMPERATURE_LOSS_RATE = 0.00000382

util.AddNetworkString("SetPermission")

ENT.Type = "point"
ENT.Base = "base_point"

ENT.Ship = nil
ENT.ShipName = nil
ENT.Index = 0

ENT.System = nil
ENT.Volume = 1000
ENT.SurfaceArea = 60

ENT.Corners = nil
ENT.Screens = nil
ENT.DoorNames = nil
ENT.Doors = nil

ENT.Bounds = nil

ENT._lastupdate = 0

ENT._temperature = 298
ENT._airvolume = 1000
ENT._shields = 1

function ENT:KeyValue(key, value)
	if key == "ship" then
		self.ShipName = tostring(value)
	elseif key == "system" then
		self.System = tostring(value)
	elseif key == "volume" then
		self.Volume = tonumber(value)
		self.SurfaceArea = math.sqrt(self.Volume) * 6
	elseif string.find(key, "^door%d*") then
		self.DoorNames = self.DoorNames or {}
		table.insert(self.DoorNames, tostring(value))
	end
end

function ENT:InitPostEntity()
	self.Corners = {}
	self.Doors = {}
	self.Screens = {}
	self.Bounds = Bounds()
	
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
			door:AddRoom(self)
			self:AddDoor(door)
			
			self.Ship:AddDoor(door)
		end
	end
	
	if self.System == "medical" then
		self._temperature = 600
	else
		self._temperature = 300
	end
	
	if self.System then
		self.System = sys.Create(self.System, self)
	end
	
	self._airvolume = self.Volume -- * math.random()
	self._shields = math.random()
	self._lastupdate = CurTime()
end

function ENT:Think()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	if self.System then self.System:Think(dt) end
	
	self._temperature = self._temperature * (1 - TEMPERATURE_LOSS_RATE * self.SurfaceArea * dt)
end

function ENT:AddCorner(index, x, y)
	self.Corners[index] = { x = x, y = y }
	self.Bounds:AddPoint(x, y)
end

function ENT:AddDoor(door)
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
		and self:HasPermission(door.Rooms[2], permission.ACCESS)
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
