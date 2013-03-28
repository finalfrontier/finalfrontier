local _mt = {}
_mt.__index = _mt

_mt._roomdict = nil
_mt._roomlist = nil

_mt._bounds = nil

_mt._nwdata = nil

function _mt:GetName()
	return self._nwdata.name
end

function _mt:_AddRoom(room)
	local name = room:GetName()
	if self._roomdict[name] then return end

	self._roomdict[name] = room
	self._roomlist[room:GetIndex()] = room

	self._bounds:AddBounds(room:GetBounds())
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

function _mt:AddDoor(door)
	self._doors[door:GetIndex()] = door
end

function _mt:GetDoors()
	return self._doors
end

function _mt:GetDoorByIndex(index)
	return self._doors[index]
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
	if #self._roomlist < table.Count(self._nwdata.roomnames) then
		for index, name in pairs(self._nwdata.roomnames) do
			if not self._roomdict[name] then
				self:_AddRoom(Room(name, self, index))
			end
		end
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
	ship._doors = {}
	ship._bounds = Bounds()

	ship._nwdata = GetGlobalTable(name)

	return setmetatable(ship, _mt)
end
