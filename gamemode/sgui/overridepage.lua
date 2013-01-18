local BASE = "page"

GUI.BaseName = BASE

GUI.Node = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.Node = sgui.Create(self, "overridenode")
	self.Node:SetSize(64, 64)
	self.Node:SetCentre(self:GetWidth() / 2, self:GetHeight() / 2)
end

function GUI:Leave()
	self.Super[BASE].Leave(self)

	self.Node = nil
end
