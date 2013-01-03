local BASE = "container"

page = {
	NONE = 0,
	STATUS = 1,
	ACCESS = 2,
	SYSTEM = 3,
	SECURITY = 4,
	OVERRIDE = 5
}

GUI.BaseName = BASE

GUI._page = page.NONE

GUI.StatusDial = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self.StatusDial = gui.Create(self.Screen, "statusdial")

	self:SetPage(page.STATUS)
end

function GUI:SetPage(newpage)
	if self._page == page.STATUS then
		self:RemoveChild(self.StatusDial)
	end

	if newpage == page.STATUS then
		self:AddChild(self.StatusDial)
	end

	self._page = newpage
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		layout.page = self._page

		if not layout.statusdial then
			layout.statusdial = {}
		end

		self.StatusDial:UpdateLayout(layout.statusdial)
	end
end

if CLIENT then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		self:SetPage(layout.page)
		self.StatusDial:UpdateLayout(layout.statusdial)
	end
end
