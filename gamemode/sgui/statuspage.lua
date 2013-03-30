local BASE = "page"

GUI.BaseName = BASE

GUI.StatusDial = nil
GUI.LeftIcon = nil
GUI.RightIcon = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.StatusDial = sgui.Create(self, "statusdial")
	self.StatusDial:SetCentre(self:GetWidth() / 2, self:GetHeight() / 2)

	self.LeftIcon = sgui.Create(self, "image")
	self.RightIcon = sgui.Create(self, "image")

	local size = self:GetWidth() / 6
	local x, y = self:GetCentre()

	self.LeftIcon:SetSize(size, size)
	self.RightIcon:SetSize(size, size)

	self.LeftIcon:SetCentre(x - size * 2.125, y)
	self.RightIcon:SetCentre(x + size * 2.125, y)

	if CLIENT and self:GetSystemIcon() then
		self.LeftIcon.Material = self:GetSystemIcon()
		self.RightIcon.Material = self:GetSystemIcon()
	else
		self.LeftIcon.Color = Color(255, 255, 255, 0)
		self.RightIcon.Color = Color(255, 255, 255, 0)
	end
end

if CLIENT then
	function GUI:Draw()
		local icon = self:GetSystemIcon()
		if icon and self.LeftIcon.Material ~= icon then
			self.LeftIcon.Material = icon
			self.RightIcon.Material = icon

			self.LeftIcon.Color = Color(255, 255, 255, 255)
			self.RightIcon.Color = Color(255, 255, 255, 255)
		end

		self.Super[BASE].Draw(self)
	end
end
