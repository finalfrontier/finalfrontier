local BASE = "page"

GUI.BaseName = BASE

GUI.StatusDial = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self.StatusDial = gui.Create(self, "statusdial")
end

if CLIENT then
	function GUI:Draw()
		self.Super[BASE].Draw(self)

		local icon = self:GetSystemIcon()
		if icon then
			surface.SetDrawColor(Color(255, 255, 255, 255))
			surface.SetMaterial(icon)
			surface.DrawTexturedRect(208, -64, 128, 128)
			surface.DrawTexturedRect(-336, -64, 128, 128)
			surface.SetMaterial(WHITE)
		end
	end
end
