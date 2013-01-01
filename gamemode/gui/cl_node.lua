local _mt = {}
_mt.__index = _mt

_mt.X = 0
_mt.Y = 0

_mt.Radius = 24

_mt.DisabledColor = Color(64, 64, 64, 255)
_mt.EnabledColor = Color(191, 191, 191, 255)
_mt.SelectedColor = Color(255, 255, 255, 255)
_mt.TextColor = Color(0, 0, 0, 255)
_mt.Label = "X"

_mt.Enabled = false

function _mt:IsCursorInside(screen)
	return self.Enabled and screen:IsCursorInsideCircle(self.X, self.Y, self.Radius)
end

function _mt:Draw(screen)
	local rad = self.Radius
	local color = self.EnabledColor
	local mouseOver = self:IsCursorInside(screen)
	if mouseOver then
		rad = math.cos(CurTime() * math.pi * 2) * self.Radius * 0.06125 + self.Radius
		color = self.SelectedColor
	elseif not self.Enabled then
		color = self.DisabledColor
	end

	surface.SetDrawColor(color)
	surface.DrawCircle(self.X, self.Y, rad)

	surface.SetDrawColor(self.TextColor)
	surface.DrawCircle(self.X, self.Y, rad - 2)

	surface.SetDrawColor(color)
	surface.DrawCircle(self.X, self.Y, rad - 6)
	
	surface.SetTextColor(self.TextColor)
	surface.SetFont("CTextSmall")
	surface.DrawCentredText(self.X, self.Y, self.Label)
end

function _mt:Click(x, y)
	return false
end

function Node(label)
	return setmetatable({ Label = label }, _mt)
end
