ENT.Type = "point"
ENT.Base = "base_point"

ENT.BaseHullHealth = 1
ENT.Rooms = nil
ENT.Doors = nil

ENT.Bounds = nil

ENT._roomlist = nil
ENT._players = nil

ENT._nwdata = nil

function ENT:KeyValue(key, value)
	if key == "hullhealth" then
		self.BaseHullHealth = tonumber(value)
		self._nwdata.basehealth = self.BaseHullHealth
	end
end

function ENT:Initialize()
	self.Rooms = {}
	self._roomlist = {}
	self.Doors = {}
	self.Bounds = Bounds()
	self._players = {}

	self._nwdata.roomnames = {}
end

function ENT:InitPostEntity()
	ships.Add(self)
	self:UpdateNWData()
end

function ENT:AddRoom(room)
	local name = room:GetName()
	if not name or self.Rooms[name] then return end

	self.Rooms[name] = room
	table.insert(self._roomlist, room)
	self.Bounds:AddBounds(room.Bounds)
	
	room.Index = #self._roomlist

	self._nwdata.rooms[room.Index] = name
	self:UpdateNWData()
end

function ENT:GetRooms()
	return self._roomlist
end

function ENT:GetRoomByIndex(index)
	return self._roomlist[index]
end

function ENT:AddDoor(door)
	if not table.HasValue(self.Doors, door) then
		table.insert(self.Doors, door)
		door.Index = #self.Doors

		self._nwdata.doors[door.Index] = door:GetName()
		self:UpdateNWData()
	end
end

function ENT:UpdateNWData()
	SetGlobalTable(self:GetName(), self._nwdata)
end

local ply_mt = FindMetaTable("Player")
function ply_mt:SetShip(ship)
	if self._ship == ship then return end
	if self._ship then
		self._ship:_removePlayer(self)
	end
	ship:_addPlayer(self)
	self._ship = ship
	self:SetNWString("ship", ship:GetName())
end

function ply_mt:GetShip()
	return self._ship
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

function ENT:IsPointInside(x, y)
	return self.Bounds:IsPointInside(x, y)
end
