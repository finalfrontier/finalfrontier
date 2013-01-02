local GLOW_STATES = {
	Color(172, 45, 51, 255),
	Color(172, 163, 48, 255),
	Color(51, 172, 45, 255)
}

local GLOW_DURATION = 1.0

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

_mt._glowstart = 0
_mt._glowstate = 0

function _mt:IsCursorInside(screen)
	return self.Enabled and screen:IsCursorInsideCircle(self.X, self.Y, self.Radius)
end

function _mt:IsGlowing()
	return self._glowstate > 0
end

function _mt:StartGlow(state)
	self._glowstate = state
	self._glowstart = CurTime()
end

function _mt:Draw(screen, overriding)
	local rad = self.Radius
	local color = self.EnabledColor
	if not overriding and self:IsCursorInside(screen) then
		rad = math.cos(CurTime() * math.pi * 2) * self.Radius * 0.06125 + self.Radius
		color = self.SelectedColor
	elseif not self.Enabled then
		color = self.DisabledColor
	end

	if self._glowstate ~= 0 then
		local dt = 1 - (CurTime() - self._glowstart) / GLOW_DURATION

		if dt <= 0 then
			self._glowstate = 0
		else
			local state = GLOW_STATES[self._glowstate]
			local r = color.r + (state.r - color.r) * dt
			local g = color.g + (state.g - color.g) * dt
			local b = color.b + (state.b - color.b) * dt
			local a = color.a + (state.a - color.a) * dt
			color = Color(r, g, b, a)
			rad = rad + 8 * dt
		end
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
