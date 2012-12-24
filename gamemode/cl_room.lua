local ROOM_UPDATE_FREQ = 1

local _index = {}
_index._lastUpdate = 0

_index._temperature = 0
_index._oldTemp = 0
_index._atmosphere = 0
_index._oldAtmo = 0
_index._shields = 0
_index._oldShld = 0

function _index:GetName()
	return self.Name
end

function _index:GetStatusLerp()
	return math.Clamp((CurTime() - self._lastUpdate) / ROOM_UPDATE_FREQ, 0, 1)
end

function _index:GetTemperature()
	return self._oldTemp + (self._temperature - self._oldTemp) * self:GetStatusLerp()
end

function _index:GetAtmosphere()
	return self._oldAtmo + (self._atmosphere - self._oldAtmo) * self:GetStatusLerp()
end

function _index:GetShields()
	return self._oldShld + (self._shields - self._oldShld) * self:GetStatusLerp()
end

function Room()
	local room = {}
	setmetatable(room, { __index = _index })
	return room
end
