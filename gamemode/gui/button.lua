local BASE = "base"

GUI.BaseName = BASE

GUI.CanClick = true

GUI.Text = "CLICK ME"

GUI.Margin = 4

GUI.Color = Color(127, 127, 127, 255)
GUI.MouseOverColor = Color(191, 191, 191, 255)
GUI.TextColor = Color(0, 0, 0, 255)

if CLIENT then
	function GUI:Draw()
		if self.CanClick and self:IsCursorInside() then
			surface.SetDrawColor(self.MouseOverColor)
		else
			surface.SetDrawColor(self.Color)
		end

		local x, y, w, h = self:GetGlobalRect()

		surface.DrawOutlinedRect(x, y, w, h)
		surface.DrawRect(x + self.Margin, y + self.Margin,
			w - self.Margin * 2, h - self.Margin * 2)

		x, y = self:GetGlobalCentre()

		surface.SetTextColor(self.TextColor)
		surface.SetFont("CTextSmall")
		surface.DrawCentredText(x, y, self.Text)

		self.Super[BASE].Draw(self)
	end
end
