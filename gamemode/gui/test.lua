local BASE = "container"

GUI.BaseName = BASE

if CLIENT then
	function GUI:Draw()
		surface.SetDrawColor(Color(255, 0, 0, 255))
		surface.DrawCircle(0, 0, 64)

		self.Super[BASE].Draw(self)
	end
end
