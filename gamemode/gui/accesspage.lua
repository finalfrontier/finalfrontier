local BASE = "page"

GUI.BaseName = BASE

GUI.RoomView = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self.RoomView = gui.Create(self, "roomview")
	self.RoomView:SetCurrentRoom(self.Screen.Room)

	if CLIENT then
		local width = self.Screen.Width
		local height = self.Screen.Height
		local margin = 16

		self.RoomView:SetBounds(-width / 2 + margin, -height / 2 + margin,
			width - margin * 2, height - margin * 2)
	end
end

if CLIENT then
	function GUI:Draw()
		self.Super[BASE].Draw(self)

		self.RoomView:Draw()
	end
end
