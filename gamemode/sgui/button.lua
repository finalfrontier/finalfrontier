local BASE = "base"

GUI.BaseName = BASE

GUI.CanClick = true

GUI.Text = "CLICK ME"

GUI.Margin = 4

GUI.Color = Color(127, 127, 127, 255)
GUI.DisabledColor = Color(64, 64, 64, 255)
GUI.HighlightColor = Color(255, 255, 255, 32)
GUI.TextColor = Color(0, 0, 0, 255)

if CLIENT then
	function GUI:Draw()
		if self.CanClick then
			surface.SetDrawColor(self.Color)
		else
			surface.SetDrawColor(self.DisabledColor)
		end
		local x, y, w, h = self:GetGlobalRect()
		surface.DrawOutlinedRect(x, y, w, h)
		surface.DrawRect(x + self.Margin, y + self.Margin,
			w - self.Margin * 2, h - self.Margin * 2)

		if self.CanClick and self:IsCursorInside() then
			surface.SetDrawColor(self.HighlightColor)
			surface.DrawRect(x + self.Margin, y + self.Margin,
				w - self.Margin * 2, h - self.Margin * 2)
		end

		local cx, cy = self:GetGlobalCentre()
		surface.SetTextColor(self.TextColor)
		surface.SetFont("CTextSmall")
		surface.DrawCentredText(cx, cy, self.Text)

		self.Super[BASE].Draw(self)
	end
end
