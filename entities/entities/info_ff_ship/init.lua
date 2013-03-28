ENT.Type = "point"
ENT.Base = "base_point"

ENT._roomdict = nil
ENT._roomlist = nil
ENT._doors = nil
ENT._bounds = nil

ENT._players = nil

ENT._nwdata = nil

function ENT:KeyValue(key, value)
	if key == "hullhealth" then
		self:_SetBaseHealth(tonumber(value))
	end
end

function ENT:Initialize()
	self._roomdict = {}
	self._roomlist = {}
	self._doors = {}
	self._bounds = Bounds()

	self._players = {}

	self._nwdata.roomnames = {}
	self._nwdata.doornames = {}
	
	self:_SetBaseHealth(1)
end

function ENT:InitPostEntity()
	ships.Add(self)
end

function ENT:_SetBaseHealth(health)
	self._nwdata.basehealth = health
	self:_UpdateNWData()
end

function ENT:GetBaseHealth()
	return self._nwdata.basehealth
end

function ENT:AddRoom(room)
	local name = room:GetName()
	if not name or self:GetRoomByName(name) then return end

	self._roomdict[name] = room
	table.insert(self._roomlist, room)
	self.Bounds:AddBounds(room:GetBounds())
	
	room:SetIndex(#self._roomlist)

	self._nwdata.rooms[room:GetIndex()] = name
	self:_UpdateNWData()
end

function ENT:GetRooms()
	return self._roomlist
end

function ENT:GetRoomByName(name)
	return self._roomdict[name]
end

function ENT:GetRoomByIndex(index)
	return self._roomlist[index]
end

function ENT:AddDoor(door)
	if not table.HasValue(self._doors, door) then
		table.insert(self._doors, door)
		door:SetIndex(#self._doors)

		self._nwdata.doornames[door:GetIndex()] = door:GetName()
		self:_UpdateNWData()
	end
end

function ENT:GetDoors()
	return self._doors
end

function ENT:GetDoorByIndex(index)
	return self._doors[index]
end

local ply_mt = FindMetaTable("Player")
function ply_mt:SetShip(ship)
	if self._ship == ship then return end
	if self._ship then
		self._ship:_RemovePlayer(self)
	end
	ship:_AddPlayer(self)
	self._ship = ship
	self:SetNWString("ship", ship:GetName())
end

function ply_mt:GetShip()
	return self._ship
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

function ENT:IsPointInside(x, y)
	return self:GetBounds():IsPointInside(x, y)
end

function ENT:_UpdateNWData()
	SetGlobalTable(self:GetName(), self._nwdata)
end
