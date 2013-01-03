local BASE = "base"

GUI.BaseName = BASE

GUI.Player = nil

if CLIENT then
	function GUI:Draw()
		local x, y = self:GetPos()

		surface.SetDrawColor(Color(255, 0, 0, 255))
		surface.DrawCircle(x, y, 64)

		surface.SetTextColor(Color(255, 255, 255, 255))
		surface.SetFont("CTextLarge")

		if self.Player then
			surface.DrawCentredText(x, y, self.Player:Nick())
		end

		self.Super[BASE].Draw(self)
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		self.Player = layout.player
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		layout.player = self.Player
	end
end
