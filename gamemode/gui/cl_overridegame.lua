local _mt = {}
_mt.__index = _mt

_mt.X = 0
_mt.Y = 0

_mt.Width = 0
_mt.Height = 0

function OverrideGame()
	return setmetatable({}, _mt)
end
