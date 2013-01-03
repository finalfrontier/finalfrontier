local BASE = "container"

page = {}
page.STATUS   = 1
page.ACCESS   = 2
page.SYSTEM   = 3
page.SECURITY = 4
page.OVERRIDE = 5

GUI.BaseName = BASE

GUI.Pages = nil

GUI._curpage = 0

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self.Pages = {
		[page.STATUS]   = gui.Create(self.Screen, "statuspage"),
		[page.ACCESS]   = gui.Create(self.Screen, "page"),
		[page.SYSTEM]   = gui.Create(self.Screen, "page"),
		[page.SECURITY] = gui.Create(self.Screen, "page"),
		[page.OVERRIDE] = gui.Create(self.Screen, "page")
	}

	self:SetCurrentPage(page.STATUS)
end

function GUI:GetCurrentPage()
	return self.Pages[self._curpage]
end

function GUI:SetCurrentPage(newpage)
	if newpage == self._curpage then return end

	local curpage = self:GetCurrentPage()
	if curpage then
		curpage:Leave()
		self:RemoveChild(curpage)
	end

	self._curpage = newpage

	curpage = self:GetCurrentPage()
	if curpage then
		self:AddChild(curpage)
		curpage:Enter()
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if layout.curpage ~= self._curpage or not layout.page then
			layout.curpage = self._curpage
			layout.page = {}
		end

		self:GetCurrentPage():UpdateLayout(layout.page)
	end
end

if CLIENT then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		self:SetCurrentPage(layout.curpage)
		self:GetCurrentPage():UpdateLayout(layout.page)
	end
end
