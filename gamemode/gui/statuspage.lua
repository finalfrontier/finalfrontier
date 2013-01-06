local BASE = "page"

GUI.BaseName = BASE

GUI.StatusDial = nil
GUI.LeftIcon = nil
GUI.RightIcon = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.StatusDial = sgui.Create(self, "statusdial")
	self.StatusDial:SetCentre(self:GetWidth() / 2, self:GetHeight() / 2)

	if self:GetSystem() then
		self.LeftIcon = sgui.Create(self, "image")
		self.RightIcon = sgui.Create(self, "image")

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
