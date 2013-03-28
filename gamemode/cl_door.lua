local _mt = {}
_mt.__index = _mt

_mt._ship = nil
_mt._rooms = nil

_mt._bounds = nil

_mt._nwdata = nil

function _mt:GetShip()
	return self._ship
end

function _mt:GetName()
	return self._nwdata.name
end

function _mt:GetIndex()
	return self._nwdata.index
end

function _mt:GetArea()
	return self._nwdata.area
end

function _mt:GetRooms()
	return self._rooms
end

function _mt:IsOpen()
	return self._nwdata.open
end

function _mt:IsClosed()
	return not self._nwdata.open
end

function _mt:IsLocked()
	return self._nwdata.locked
end

function _mt:IsUnlocked()
	return not self._nwdata.locked
end

function Door(name, ship, index)
	door = {}
	door._ship = ship

	door._nwdata = GetGlobalTable(name)
	door._nwdata.name = name
	door._nwdata.index = index

	return setmetatable(door, _mt)
end
