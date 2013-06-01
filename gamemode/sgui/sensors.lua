local BASE = "page"

GUI.BaseName = BASE

GUI._coordLabel = nil
GUI._grid = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._grid = sgui.Create(self, "sectorgrid")
    self._grid:SetOrigin(8, 8)
    self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 16)

    self._coordLabel = sgui.Create(self, "label")
    self._coordLabel.AlignX = TEXT_ALIGN_CENTER
    self._coordLabel.AlignY = TEXT_ALIGN_CENTER
    self._coordLabel:SetOrigin(self._grid:GetRight() + 16, self:GetHeight() - 48)
    self._coordLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
end

if CLIENT then
    function GUI:Draw()
        local x, y = 0, 0
        if self._grid:IsCursorInside() then
            x, y = self._grid:GetCursorPos()
            x = x - self._grid:GetLeft()
            y = y - self._grid:GetTop()
            x, y = self._grid:ScreenToCoordinate(x, y)
        else
            x, y = self:GetShip():GetCoordinates()
        end

        self._coordLabel.Text = "x: " .. FormatNum(x, 1, 2) .. ", y: " .. FormatNum(y, 1, 2)

        self._grid:SetCentreCoordinates(self:GetShip():GetCoordinates())
        self.Super[BASE].Draw(self)
    end
end
