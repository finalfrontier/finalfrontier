local BASE = "container"

GUI.BaseName = BASE

GUI.Color = Color(191, 191, 191, 255)

GUI._window = nil
GUI._currentTabMenu = 0

GUI.TabHeight = 48
GUI.TabMargin = 8

page = {}

function GUI:Initialize()
	self.Super[BASE].Initialize(self)
	
	self._window = {}
end

function GUI:AddMenu()
	local _nextMenu = #self._window
	self._window[_nextMenu].TabMenu = sgui.Create(self:GetScreen(), "tabmenu")
	self._window[_nextMenu].TabMenu:SetSize(self:GetSize())
	self._window[_nextMenu].TabMenu:SetCentre(self:GetCentre())
	self._window[_nextMenu].Tabs = {}
	self._window[_nextMenu].Tabs[page[0].number] = self._window[_nextMenu].TabMenu:AddTab(page[0].name)
	if not page[1] then return self._window[_nextMenu] end
	self._tpages[_lastPage].Tabs[page[1].number] = self._window[_nextMenu].TabMenu:AddTab(page[1].name)
	if not page[2] then return self._window[_nextMenu] end
	self._window[_nextMenu].Tabs[page[2].number] = self._window[_nextMenu].TabMenu:AddTab(page[2].name)
	if not page[3] then return self._window[_lastPage] end
	self._window[_nextMenu].Tabs[page[3].number] = self._window[_nextMenu].TabMenu:AddTab(page[3].name)
	return self._window[_nextMenu]
end

function GUI:SetTab(num, text)
	page[num] = {}
	page[num].number = num
	page[num].name = text
end

function GUI:GetCurrentTabMenu()
	return self._currentTabMenu
end

function GUI:GetWindow()
	return self._window	
end

function GUI:GetDefaultTabMenu()
	return self._window[0].TabMenu
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

function GUI:GetCurrentIndexes()
	return _currentTabMenu, self._window[_currentTabMenu].TabMenu:GetCurrentIndex()
end

function GUI:SetCurrentIndex(index)
    if index < 1 or index > #self._window then
        index = 0
    end

    if self._currentTabMenu ~= index then
        self._currentTabMenu = index
        self:OnChangeCurrent(index)
    end
end

function GUI:GetCurrentTabIndex()
	return self._currentTabMenu * self._window[self._currentTabMenu].TabMenu:GetCurrentIndex()	
end

function GUI:GetCurrent()
	return self._window[_currentTabMenu].TabMenu
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        self.GetCurrent():UpdateLayout(layout)
    end
end

if CLIENT then
    function GUI:Draw()
        self.GetCurrent():Draw()

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)
	
	self.GetCurrent():UpdateLayout(layout)
        self:SetCurrentIndex(layout.current)
    end
end
