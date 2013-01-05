local BASE = "page"

GUI.BaseName = BASE

GUI.StatusDial = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.StatusDial = gui.Create(self, "statusdial")
	self.StatusDial:SetCentre(self:GetCentre())
end

function GUI:Leave()
	self.Super[BASE].Leave(self)

	self.StatusDial:Remove()
end

if CLIENT then
	function GUI:Draw()
		self.Super[BASE].Draw(self)

		local icon = self:GetSystemIcon()
		if icon then
			local x, y = self:GetGlobalCentre()
			local size = self:GetWidth() / 6
			surface.SetDrawColor(Color(255, 255, 255, 255))
			surface.SetMaterial(icon)
			surface.DrawTexturedRect(x + 1.625 * size, y - size / 2, size, size)
			surface.DrawTexturedRect(x - 2.625 * size, y - size / 2, size, size)
			surface.SetMaterial(WHITE)
		end
	end
end
