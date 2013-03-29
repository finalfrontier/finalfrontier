local _mt = {}
_mt.__index = _mt

_mt._roomdict = nil
_mt._roomlist = nil
_mt._doorlist = nil

_mt._bounds = nil

_mt._nwdata = nil

function _mt:GetName()
	return self._nwdata.name
end

function _mt:_UpdateBounds()
	local bounds = Bounds()
	for _, room in pairs(self:GetRooms()) do
		if not room:GetBounds() then return end
		bounds:AddBounds(room:GetBounds())
	end
	self._bounds = bounds
end

function _mt:GetBounds()
	return self._bounds
end

function _mt:GetRoomNames()
	return self._nwdata.roomnames or {}
end

function _mt:_UpdateRooms()
	for index, name in pairs(self:GetDoorNames()) do
		if self._roomdict[name] then return end

		local room = Room(name, self, index)
		self._roomdict[name] = room
		self._roomlist[index] = room
	end
end

function _mt:GetRooms()
	return self._roomlist
end

function _mt:GetRoomByName(name)
	return self._roomdict[name]
end

function _mt:GetRoomByIndex(index)
	return self._roomlist[index]
end

function _mt:_UpdateDoors()
	for index, name in pairs(self:GetDoorNames()) do
		if self._doorlist[index] then return end
		
		self._roomdict[name] = Door(name, self, index)
	end
end

function _mt:AddDoor(door)
	self._doorlist[door:GetIndex()] = door
end

function _mt:GetDoorNames()
	return self._nwdata.doornames or {}
end

function _mt:GetDoors()
	return self._doorlist
end

function _mt:GetDoorByIndex(index)
	return self._doorlist[index]
end

function _mt:FindTransform(screen, x, y, width, height)
	local bounds = Bounds(x, y, width, height)
	return FindBestTransform(self:GetBounds(), bounds, true, true)
end

function _mt:ApplyTransform(transform)
	for _, room in pairs(self:GetRooms()) do
		room:ApplyTransform(transform)
	end

	for _, door in ipairs(self:GetDoors()) do
		door:ApplyTransform(transform)
	end
end

function _mt:Think()
	if table.Count(self:GetRooms()) < table.Count(self:GetRoomNames()) then
		self:_UpdateRooms()
	end

	if table.Count(self:GetDoors()) < table.Count(self:GetDoorNames()) then
		self:_UpdateDoors()
	end

	if not self:GetBounds() and and table.Count(self:GetRoomNames()) > 0 and
		table.Count(self:GetRooms()) == table.Count(self:GetRoomNames()) then
		self:_UpdateBounds()
	end

	for _, room in pairs(self:GetRooms()) do
		room:Think()
	end

	for _, door in ipairs(self:GetDoors()) do
		door:Think()
	end
end

function _mt:Draw(screen, roomColorFunc, doorColorFunc)
	for _, room in pairs(self:GetRooms()) do
		room:Draw(screen, roomColorFunc)
	end

	for _, door in ipairs(self:GetDoors()) do
		door:Draw(screen, doorColorFunc)
	end
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetShip()
	if not self:GetNWString("ship") then return nil end
	return ships.FindByName(self:GetNWString("ship"))
end

function Ship(name)
	local ship = {}

	ship._roomdict = {}
	ship._roomlist = {}
	ship._doorlist = {}

	ship._nwdata = GetGlobalTable(name)

	return setmetatable(ship, _mt)
end
