ENT.Type = "point"
ENT.Base = "base_point"

ENT._roomdict = nil
ENT._roomlist = nil
ENT._doors = nil
ENT._bounds = nil

ENT._players = nil

ENT._nwdata = nil
ENT._object = nil

function ENT:KeyValue(key, value)
	if key == "health" then
		self:_SetBaseHealth(tonumber(value))
	end
end

function ENT:Initialize()
	self._roomdict = {}
	self._roomlist = {}
	self._doors = {}
	self._bounds = Bounds()

	self._players = {}

	if not self._nwdata then
		self._nwdata = {}
	end

	self._nwdata.roomnames = {}
	self._nwdata.doornames = {}

	self._nwdata.range = 0.5

	self._nwdata.name = self:GetName()
	
	if not self:GetBaseHealth() then
		self:_SetBaseHealth(1)
	end
end

function ENT:GetCoordinates()
	return self._object:GetCoordinates()
end

function ENT:GetRotation()
	return self._object:GetRotation()
end

function ENT:GetRange()
	return self._nwdata.range
end

function ENT:SetRange(range)
	self._nwdata.range = value
	self:_UpdateNWData()
end

function ENT:InitPostEntity()
	self._object = ents.Create("info_ff_object")
	self._object:SetPos(universe:GetWorldPos())
	self._object:Spawn()
	ships.Add(self)
end

function ENT:GetBounds()
	return self._bounds
end

function _mt:GetOrigin()
	return self._nwdata.x, self._nwdata.y
end

function ENT:_SetBaseHealth(health)
	if not self._nwdata then self._nwdata = {} end

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
	self:GetBounds():AddBounds(room:GetBounds())
	
	room:SetIndex(#self._roomlist)

	self._nwdata.roomnames[room:GetIndex()] = name
	self:_UpdateNWData()
end

function ENT:GetRoomNames()
	return self._nwdata.roomnames
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

function ENT:GetDoorNames()
	return self._nwdata.doornames
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
