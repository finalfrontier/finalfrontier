local BASE = "page"

GUI.BaseName = BASE

GUI._grid = nil
GUI._weapons = nil

function GUI:Enter()
    local gridSize = self:GetHeight() - 16
    local colWidth = self:GetWidth() - gridSize - 24
    self._grid = sgui.Create(self, "sectorgrid")
    self._grid:SetOrigin(8, 8)
    self._grid:SetSize(gridSize, gridSize)
    self._grid:SetCentreObject(nil)
    self._grid:SetScale(math.max(self._grid:GetMinScale(), self._grid:GetMinSensorScale()))

    self._zoomLabel = sgui.Create(self, "label")
    self._zoomLabel.AlignX = TEXT_ALIGN_CENTER
    self._zoomLabel.AlignY = TEXT_ALIGN_CENTER
    self._zoomLabel:SetOrigin(self._grid:GetRight() + 8, 16)
    self._zoomLabel:SetSize(colWidth, 32)
    self._zoomLabel.Text = "View Zoom"

    self._zoomSlider = sgui.Create(self, "slider")
    self._zoomSlider:SetOrigin(self._grid:GetRight() + 8, self._zoomLabel:GetBottom() + 8)
    self._zoomSlider:SetSize(colWidth, 48)

    if SERVER then
        local min = self._grid:GetMinScale()
        local max = self._grid:GetMaxScale()
        self._zoomSlider.Value = math.sqrt((self._grid:GetScale() - min) / (max - min))
        function self._zoomSlider.OnValueChanged(slider, value)
            min = self._grid:GetMinScale()
            max = self._grid:GetMaxScale()
            self._grid:SetScale(min + math.pow(value, 2) * (max - min))
        end
    end

    local wpnHeight = 80

    self._weapons = {}
    for i = 1, 3 do
        local wpn = sgui.Create(self, "weaponview")
        local yof = 4 - i
        wpn:SetOrigin(self._grid:GetRight() + 8, self:GetHeight() - yof * (wpnHeight + 8))
        wpn:SetSize(colWidth, wpnHeight)
        wpn:SetWeaponSlot(moduletype.weapon1 + i - 1)
        self._weapons[i] = wpn
    end
end
