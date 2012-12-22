local _sliderIndex = {}

_sliderIndex.X = 0
_sliderIndex.Y = 0

_sliderIndex.Width = 256
_sliderIndex.Height = 64

_sliderIndex.Value = 0
_sliderIndex.Damage = 0

_sliderIndex.Color = Color(127, 127, 127, 255)

function _sliderIndex:Draw(screen)
	surface.SetDrawColor(self.Color)
	surface.DrawOutlinedRect(self.X, self.Y, self.Width, self.Height)
	surface.DrawRect(self.X + 4, self.Y + 4, (self.Width - 8) * math.min(self.Value, 1), self.Height - 8)
end

function _sliderIndex:Click(x, y)
	if x >= self.X - 32 and y >= self.Y - 8
		and x <= self.X + self.Width + 64 and y <= self.Y + self.Height + 16 then
		self.Value = math.Clamp((x - self.X - 4) / (self.Width - 8), 0, 1)
		return true
	end
	return false
end

function Slider()
	local slider = {}
	setmetatable(slider, { __index = _sliderIndex })
	return slider
end
