local BLACK = Color(0, 0, 0, 255)
local BASE = "base"

GUI.BaseName = BASE

GUI.Text = "UNNAMED"
GUI.Color = Color(191, 191, 191, 255)

if CLIENT then
	function GUI:Draw()
		if self:HasParent() and self:GetParent():GetCurrent() == self then
			surface.DrawRect(self:GetGlobalRect())
			surface.SetTextColor(BLACK)
		else
			surface.SetTextColor(self.Color)
		end

		local x, y = self:GetGlobalCentre()
		surface.SetFont("CTextSmall")
		surface.DrawCentredText(x, y, self.Text)
		
		self.Super[BASE].Draw(self)
	end
end
