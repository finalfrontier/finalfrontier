local BASE = "page"

GUI.BaseName = BASE

GUI.ShipView = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.ShipView = sgui.Create(self, "shipview")
	self.ShipView:SetCurrentShip(self:GetShip())

	local margin = 16

	self.ShipView:SetBounds(Bounds(
		margin,
		margin,
		self:GetWidth() - margin * 2,
		self:GetHeight() - margin * 2
	))
end
