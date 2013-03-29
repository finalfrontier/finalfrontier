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

function _mt:GetPos()
	return self._nwdata.x, self._nwdata.y
end

function _mt:GetAngle()
	return self._nwdata.angle
end

function _mt:GetRooms()
	return self._rooms
end

function _mt:_UpdateBounds()
	self._bounds = Bounds()
	for _, v in pairs(self:GetCorners()) do
		self._bounds:AddPoint(v.x, v.y)
	end
end

function _mt:GetBounds()
	return self._bounds
end

function _mt:GetCorners()
	return self._nwdata.corners
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

function _mt:Think()
	if not self:GetBounds() and self:GetCorners() then
		self._UpdateBounds()
	end
end

function Door(name, ship, index)
	door = {}
	door._ship = ship
	door._rooms = {}

	door._nwdata = GetGlobalTable(name)
	door._nwdata.name = name
	door._nwdata.index = index

	return setmetatable(door, _mt)
end
