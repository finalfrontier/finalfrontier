local BASE = "page"

GUI.BaseName = BASE

GUI.TestButton = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.TestButton = gui.Create(self, "button")
	self.TestButton:SetSize(256, 64)
	self.TestButton:SetCentre(self:GetWidth() / 2, self:GetHeight() / 2)
end

function GUI:Leave()
	self.Super[BASE].Leave(self)

	self.TestButton:Remove()
end
