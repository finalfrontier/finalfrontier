local ROOM_UPDATE_FREQ = 1

local _mt = {}
_mt.__index = _mt
_mt._lastUpdate = 0

_mt._temperature = 0
_mt._oldTemp = 0
_mt._atmosphere = 0
_mt._oldAtmo = 0
_mt._shields = 0
_mt._oldShld = 0

function _mt:GetName()
	return self.Name
end

function _mt:GetStatusLerp()
	return math.Clamp((CurTime() - self._lastUpdate) / ROOM_UPDATE_FREQ, 0, 1)
end

function _mt:GetTemperature()
	return self._oldTemp + (self._temperature - self._oldTemp) * self:GetStatusLerp()
end

function _mt:GetAtmosphere()
	return self._oldAtmo + (self._atmosphere - self._oldAtmo) * self:GetStatusLerp()
end

function _mt:GetShields()
	return self._oldShld + (self._shields - self._oldShld) * self:GetStatusLerp()
end

function Room()
	return setmetatable({}, _mt)
end
