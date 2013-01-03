local BASE = "base"

GUI.BaseName = BASE

GUI.Text = "X"

if CLIENT then
	function GUI:Draw()
		local x, y = self:GetPos()

		surface.SetDrawColor(Color(255, 0, 0, 255))
		surface.DrawCircle(x, y, 64)

		surface.SetTextColor(Color(255, 255, 255, 255))
		surface.SetFont("CTextLarge")
		surface.DrawCentredText(x, y, self.Text)

		self.Super[BASE].Draw(self)
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		self.Text = layout.text
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		layout.text = self.Text
	end
end
