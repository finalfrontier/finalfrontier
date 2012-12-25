local _mt = {}
_mt.__index = _mt

_mt.X = 0
_mt.Y = 0

_mt.Width = 256
_mt.Height = 64

_mt.Value = 0
_mt.Damage = 0

_mt.Snap = 100

_mt.Color = Color(127, 127, 127, 255)

function _mt:Draw(screen)
	surface.SetDrawColor(self.Color)
	surface.DrawOutlinedRect(self.X, self.Y, self.Width, self.Height)
	surface.DrawRect(self.X + 4, self.Y + 4, (self.Width - 8) * math.min(self.Value, 1), self.Height - 8)
end

function _mt:Click(x, y)
	if x >= self.X - 32 and y >= self.Y - 8
		and x <= self.X + self.Width + 64 and y <= self.Y + self.Height + 16 then
		self.Value = math.Clamp((x - self.X - 4) / (self.Width - 8), 0, 1)
		self.Value = math.Round(self.Value * self.Snap) / self.Snap
		return true
	end
	return false
end

function Slider()
	return setmetatable({}, _mt)
end
