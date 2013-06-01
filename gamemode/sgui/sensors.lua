local BASE = "page"

GUI.BaseName = BASE

GUI._coordLabel = nil
GUI._sectorLabel = nil
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

    self._sectorLabel = sgui.Create(self, "label")
    self._sectorLabel.AlignX = TEXT_ALIGN_CENTER
    self._sectorLabel.AlignY = TEXT_ALIGN_CENTER
    self._sectorLabel:SetOrigin(self._grid:GetRight() + 16, self._coordLabel:GetTop() - 48)
    self._sectorLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
end

if CLIENT then
    function GUI:Draw()
        local x, y = self:GetShip():GetCoordinates()
        --[[if self._grid:IsCursorInside() then
            x, y = self._grid:GetCursorPos()
            x = x - self._grid:GetLeft()
            y = y - self._grid:GetTop()
            x, y = self._grid:ScreenToCoordinate(x, y)
        end]]

        self._coordLabel.Text = "x: " .. FormatNum(x, 1, 2) .. ", y: " .. FormatNum(y, 1, 2)

        self._grid:SetCentreCoordinates(self:GetShip():GetCoordinates())
        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        local sectors = ents.FindByClass("info_ff_sector")
        local sx, sy = self:GetShip():GetCoordinates()
        sx = math.floor(sx) + 0.5
        sy = math.floor(sy) + 0.5
        for _, sector in pairs(sectors) do
            local x, y = sector:GetCoordinates()
            if math.abs(x - sx) < 0.5 and math.abs(y - sy) < 0.5 then
                self._sectorLabel.Text = sector:GetSectorName()
                break
            end
        end
    end
end
