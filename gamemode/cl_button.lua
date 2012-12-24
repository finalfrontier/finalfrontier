local _mt = {}
_mt.__index = _mt

_mt.X = 0
_mt.Y = 0

_mt.Width = 256
_mt.Height = 64

_mt.Color = Color(127, 127, 127, 255)
_mt.TextColor = Color(0, 0, 0, 255)
_mt.Text = "CLICK ME"

function _mt:Draw(screen)
	if screen._cursorx >= self.X - 8 and screen._cursory >= self.Y - 8 and
		screen._cursorx <= self.X + self.Width + 16 and screen._cursory <= self.Y + self.Height + 16 then
		surface.SetDrawColor(Color(self.Color.r + 64, self.Color.g + 64, self.Color.b + 64))
	else
		surface.SetDrawColor(self.Color)
	end
	surface.DrawOutlinedRect(self.X, self.Y, self.Width, self.Height)
	surface.DrawRect(self.X + 4, self.Y + 4, self.Width - 8, self.Height - 8)
	
	surface.SetTextColor(self.TextColor)
	surface.SetFont("CTextSmall")
	surface.DrawCentredText(self.X + self.Width / 2, self.Y + self.Height / 2, self.Text)
end

function _mt:Click(x, y)
	if x >= self.X - 8 and y >= self.Y - 8 and
		x <= self.X + self.Width + 16 and y <= self.Y + self.Height + 16 then
		return true
	end
	return false
end

function Button()
	local button = {}
	setmetatable(button, _mt)
	return button
end
