local BLACK = Color(0, 0, 0, 255)

local _mt = {}
_mt.__index = _mt

_mt.X = 0
_mt.Y = 0

_mt.Width = 768
_mt.Height = 64

_mt._options = {}
_mt._current = 0
_mt._totwidth = 0

_mt.Color = Color(191, 191, 191, 255)

function _mt:AddOption(option)
	surface.SetFont("CTextSmall")
	local width = 1 --surface.GetTextSize(option)
	table.insert(self._options, { Value = option, Width = width })
	self._totwidth = self._totwidth + width

	if self._current == 0 then
		self:SetCurrentIndex(1)
	end
end

function _mt:GetCurrentIndex()
	return self._current
end

function _mt:GetCurrent()
	return self._options[self._current].Value
end

function _mt:SetCurrentIndex(index)
	self._current = index
end

function _mt:GetOption(index)
	return self._options[index].Value
end

function _mt:GetOptionCount()
	return #self._options
end

function _mt:SetCurrent(option)
	for i, v in ipairs(self._options) do
		if v.Value == option then
			self._current = i
			return
		end
	end
end

function _mt:Draw(screen)
	surface.SetDrawColor(self.Color)
	surface.DrawOutlinedRect(self.X, self.Y, self.Width, self.Height)

	surface.SetFont("CTextSmall")

	local cursX, cursY = screen:GetCursorPos()

	local scale = self.Width / self._totwidth
	local left = self.X
	local midy = self.Y + self.Height / 2
	local margin = 8
	for i, v in ipairs(self._options) do
		local right = left + v.Width * scale
		local midx = (left + right) * 0.5

		if i == self._current then
			surface.DrawRect(left + margin, self.Y + margin,
				right - left - margin * 2, self.Height - margin * 2)
			surface.SetTextColor(BLACK)
		else
			if cursY >= self.Y and cursY < self.Y + self.Height
				and cursX >= left and cursX < right then
				surface.DrawOutlinedRect(left + margin, self.Y + margin,
					right - left - margin * 2, self.Height - margin * 2)
			end
			surface.SetTextColor(self.Color)
		end

		surface.DrawCentredText(midx, midy, v.Value)

		left = right
	end
end

function _mt:Click(x, y)
	if x < self.X or x >= self.X + self.Width
		or y < self.Y or y >= self.Y + self.Height then
		return nil
	end

	local scale = self.Width / self._totwidth
	local left = self.X
	for i, v in ipairs(self._options) do
		local right = left + v.Width * scale
		if x < right then
			--self:SetCurrentIndex(i)
			return i
		end
		left = right
	end
	return nil
end

function TabMenu(...)
	local tabmenu = setmetatable({ _options = {} }, _mt)
	local options = {...}
	if options and #options > 0 then
		for _, v in ipairs(options) do
			tabmenu:AddOption(v)
		end
	end

	return tabmenu
end
