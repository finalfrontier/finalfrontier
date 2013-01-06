local BLACK = Color(0, 0, 0, 255)
local BASE = "container"

GUI.BaseName = BASE

GUI.Color = Color(191, 191, 191, 255)

GUI._tabs = nil
GUI._current = 0

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self._tabs = {}
end

function GUI:AddTab(text)
	local tab = gui.Create(self, "tab")
	tab.Text = text

	table.insert(self._tabs, tab)

	if self._current == 0 then
		self:SetCurrentIndex(1)
	end

	self:UpdateTabPositions()
end

function GUI:SetBounds(bounds)
	self.Super[BASE].SetBounds(self, bounds)
	self:UpdateTabPositions()
end

function GUI:GetCurrentIndex()
	return self._current
end

function GUI:GetCurrent()
	return self._tabs[self._current]
end

function GUI:SetCurrentIndex(index)
	if index < 1 or index > #self._tabs then
		self._current = 0
	else
		self._current = index
	end
end

function GUI:SetCurrent(tab)
	for i, v in ipairs(self._tabs) do
		if v == tab then
			self:SetCurrentIndex(i)
			return
		end
	end
end

function GUI:GetTab(index)
	return self._tabs[index]
end

function GUI:GetTabCount()
	return #self._tabs
end

function GUI:UpdateTabPositions()
	local margin = 8
	local width = (self:GetWidth() - margin) / self:GetTabCount()

	local left = margin

	for i, tab in ipairs(self._tabs) do
		tab:SetHeight(self:GetHeight() - margin * 2)
		tab:SetWidth(width - margin)
		tab:SetOrigin(left, margin)
		left = left + width
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		layout.current = self:GetCurrentIndex()
	end
end

if CLIENT then
	function GUI:Draw()
		surface.SetDrawColor(self.Color)
		surface.DrawOutlinedRect(self:GetGlobalRect())

		self.Super[BASE].Draw(self)
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		self:SetCurrentIndex(layout.current)
	end
end
