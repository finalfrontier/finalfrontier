local BASE = "container"

GUI.BaseName = BASE

GUI.Color = Color(191, 191, 191, 255)

GUI._tpages = nil
GUI._currenttpage = 0

GUI.TabHeight = 48
GUI.TabMargin = 8

page = {}

function GUI:Initialize()
	self.Super[BASE].Initialize(self)
	
	self._tpages = {}
end

function GUI:AddMenu()
	_lastPage = #self.tpages
	self._tpages[_lastPage].TabMenu = sgui.Create(self:GetScreen(), "tabmenu")
	self._tpages[_lastPage].TabMenu:SetSize(self:GetWidth() - self.TabMargin * 2, self.TabHeight)
	self._tpages[_lastPage].TabMenu:SetCentre(self:GetWidth() / 2, self.TabHeight / 2 + self.TabMargin)
	self._tpages[_lastPage].Tabs = {}
	self._tpages[_lastPage].Tabs[page[0].number] = self._tpages[_lastPage].TabMenu:AddTab(page[0].name)
	self._tpages[_lastPage].Tabs[page[1].number] = self._tpages[_lastPage].TabMenu:AddTab(page[1].name)
	self._tpages[_lastPage].Tabs[page[2].number] = self._tpages[_lastPage].TabMenu:AddTab(page[2].name)
	self._tpages[_lastPage].Tabs[page[3].number] = self._tpages[_lastPage].TabMenu:AddTab(page[3].name)
	return self._tpages[_lastPage]
end

function GUI:SetPage(num, text)
	page[num] = {}
	page[num].number = num
	page[num].name = text
end

function GUI:GetCurrentTabPage()
	return self._currenttpage
end

function GUI:GetTabPages()
	return self._tpages	
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
