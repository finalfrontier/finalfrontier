local BASE = "container"

GUI.BaseName = BASE

GUI.Color = Color(191, 191, 191, 255)

GUI._window = nil
GUI._currentWindow = 0

GUI.TabHeight = 48
GUI.TabMargin = 8

page = {}

function GUI:Initialize()
	self.Super[BASE].Initialize(self)
	
	self._window = {}
end

function GUI:AddMenu()
	_lastPage = #self._window
	self._window[_lastPage].TabMenu = sgui.Create(self:GetScreen(), "tabmenu")
	self._window[_lastPage].TabMenu:SetSize(self:GetWidth() - self.TabMargin * 2, self.TabHeight)
	self._window[_lastPage].TabMenu:SetCentre(self:GetWidth() / 2, self.TabHeight / 2 + self.TabMargin)
	self._window[_lastPage].Tabs = {}
	self._window[_lastPage].Tabs[page[0].number] = self._window[_lastPage].TabMenu:AddTab(page[0].name)
	self._tpages[_lastPage].Tabs[page[1].number] = self._window[_lastPage].TabMenu:AddTab(page[1].name)
	self._window[_lastPage].Tabs[page[2].number] = self._window[_lastPage].TabMenu:AddTab(page[2].name)
	self._window[_lastPage].Tabs[page[3].number] = self._window[_lastPage].TabMenu:AddTab(page[3].name)
	return self._window[_lastPage]
end

function GUI:SetTab(num, text)
	page[num] = {}
	page[num].number = num
	page[num].name = text
end

function GUI:GetCurrentWindow()
	return self._currentWindow
end

function GUI:GetWindow()
	return self._window	
end

function GUI:GetAllTabs()
	local result = {}
	for k, v ipairs(self._tpages) do
		for kk, vv ipairs(v.Tabs) do
			result = result + vv
		end
	end
	return result
end
