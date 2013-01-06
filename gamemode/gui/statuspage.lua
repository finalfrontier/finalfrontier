local BASE = "page"

GUI.BaseName = BASE

GUI.StatusDial = nil
GUI.LeftIcon = nil
GUI.RightIcon = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.StatusDial = gui.Create(self, "statusdial")
	self.StatusDial:SetCentre(self:GetWidth() / 2, self:GetHeight() / 2)

	self.LeftIcon = gui.Create(self, "image")
	self.RightIcon = gui.Create(self, "image")

	if self:GetSystem() then
		local size = self:GetWidth() / 6
		local x, y = self:GetCentre()

		self.LeftIcon:SetSize(size, size)
		self.RightIcon:SetSize(size, size)

		self.LeftIcon:SetCentre(x - size * 2.125, y)
		self.RightIcon:SetCentre(x + size * 2.125, y)

		if CLIENT then
			self.LeftIcon.Material = self:GetSystemIcon()
			self.RightIcon.Material = self:GetSystemIcon()
		end
	end
end
