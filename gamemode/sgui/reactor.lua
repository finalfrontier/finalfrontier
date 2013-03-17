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
        margin * 0.5,
        self:GetWidth() - margin * 2,
        self:GetHeight() - margin * 1.5
    ))
end
