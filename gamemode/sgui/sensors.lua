local BASE = "page"

GUI.BaseName = BASE

GUI._zoomLabel = nil
GUI._zoomSlider = nil
GUI._coordLabel = nil
GUI._sectorLabel = nil
GUI._grid = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._grid = sgui.Create(self, "sectorgrid")
    self._grid:SetOrigin(8, 8)
    self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 16)

    self._grid:SetCentreObject(self:GetShip():GetObject())
    self._grid:SetScale(self._grid:GetMinScale())

    self._zoomLabel = sgui.Create(self, "label")
    self._zoomLabel.AlignX = TEXT_ALIGN_CENTER
    self._zoomLabel.AlignY = TEXT_ALIGN_CENTER
    self._zoomLabel:SetOrigin(self._grid:GetRight() + 16, 16)
    self._zoomLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
    self._zoomLabel.Text = "View Zoom"

    self._zoomSlider = sgui.Create(self, "slider")
    self._zoomSlider:SetOrigin(self._grid:GetRight() + 16, self._zoomLabel:GetBottom() + 8)
    self._zoomSlider:SetSize(self:GetWidth() * 0.4 - 16, 48)
    if SERVER then
        self._zoomSlider.Value = 0
        function self._zoomSlider.OnValueChanged(slider, value)
            local min = self._grid:GetMinScale()
            local max = self._grid:GetMaxScale()
            self._grid:SetScale(min + math.pow(value, 2) * (max - min))
        end
    end

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

        self._coordLabel.Text = "x: " .. FormatNum(x, 1, 2) .. ", y: " .. FormatNum(y, 1, 2)

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        local sectors = ents.FindByClass("info_ff_sector")
        local sx, sy = self:GetShip():GetCoordinates()
        sx = math.floor(sx)
        sy = math.floor(sy)
        for _, sector in pairs(sectors) do
            local x, y = sector:GetCoordinates()
            x = math.floor(x)
            y = math.floor(y)
            if math.abs(x - sx) < 0.5 and math.abs(y - sy) < 0.5 then
                self._sectorLabel.Text = sector:GetSectorName()
                break
            end
        end
    end
end
