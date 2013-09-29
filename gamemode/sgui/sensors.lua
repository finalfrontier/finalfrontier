local BASE = "page"

GUI.BaseName = BASE

GUI._inspected = nil
GUI._oldScale = nil

GUI._zoomLabels = nil
GUI._zoomSlider = nil
GUI._scanPowerLabel = nil
GUI._chargeSlider = nil
GUI._scanPowerBar = nil
GUI._scanButton = nil
GUI._selectedLabel = nil
GUI._inspectButton = nil
GUI._coordLabel = nil
GUI._sectorLabel = nil
GUI._grid = nil

GUI._shipView = nil
GUI._closeButton = nil

function GUI:Inspect(obj)
    self:RemoveAllChildren()
    if obj then
        self._inspected = obj
        self._oldScale = self._grid:GetScale()

        self._zoomLabels = nil
        self._zoomSlider = nil
        self._scanPowerLabel = nil
        self._chargeSlider = nil
        self._scanPowerBar = nil
        self._scanButton = nil
        self._selectedLabel = nil
        self._inspectButton = nil
        self._coordLabel = nil
        self._sectorLabel = nil
        self._grid = nil

        self._shipView = sgui.Create(self, "shipview")
        self._shipView:SetCurrentShip(ships.GetByName(obj:GetObjectName()))
        self._shipView:SetBounds(Bounds(16, 8, self:GetWidth() - 32, self:GetHeight() - 88))

        self._closeButton = sgui.Create(self, "button")
        self._closeButton:SetOrigin(16, self:GetHeight() - 48 - 16)
        self._closeButton:SetSize(self:GetWidth() - 32, 48)
        self._closeButton.Text = "Return to Sector View"

        if SERVER then
            function self._closeButton.OnClick(btn, x, y, button)
                self:Inspect(nil)
                self._grid:SetCentreObject(obj)
                self:GetScreen():UpdateLayout()
                return true
            end
        end
    else
        self._inspected = nil
        self._shipView = nil
        self._closeButton = nil

        self._grid = sgui.Create(self, "sectorgrid")
        self._grid:SetOrigin(8, 8)
        self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 56)
        self._grid:SetCentreObject(nil)
        self._grid:SetScale(math.max(self._grid:GetMinScale(), self._oldScale or self._grid:GetMinSensorScale()))

        if SERVER then
            function self._grid.OnClickSelectedObject(grid, obj, button)
                if obj:GetObjectType() == objtype.ship then
                    self:Inspect(obj)
                    self:GetScreen():UpdateLayout()
                    return true
                end
                return false
            end
        end
        
        local lblMinus = sgui.Create(self, "label")
        lblMinus.AlignX = TEXT_ALIGN_CENTER
        lblMinus.AlignY = TEXT_ALIGN_CENTER
        lblMinus:SetOrigin(self._grid:GetLeft(), self._grid:GetBottom() + 8)
        lblMinus:SetSize(32, 32)
        lblMinus.Text = "[-]"

        local lblPlus = sgui.Create(self, "label")
        lblPlus.AlignX = TEXT_ALIGN_CENTER
        lblPlus.AlignY = TEXT_ALIGN_CENTER
        lblPlus:SetOrigin(self._grid:GetRight() - 32, self._grid:GetBottom() + 8)
        lblPlus:SetSize(32, 32)
        lblPlus.Text = "[+]"

        self._zoomLabels = {minus = lblMinus, plus = lblPlus}

        self._zoomSlider = sgui.Create(self, "slider")
        self._zoomSlider:SetOrigin(lblMinus:GetRight() + 8, self._grid:GetBottom() + 8)
        self._zoomSlider:SetSize(lblPlus:GetLeft() - lblMinus:GetRight() - 16, 32)

        if SERVER then
            local min = self._grid:GetMinScale()
            local max = self._grid:GetMaxScale()

            self._zoomSlider.Value = self:GetScreen().Storage.ZoomSliderValue or math.sqrt((self._grid:GetScale() - min) / (max - min))
            self:GetScreen().Storage.ZoomSliderValue = self._zoomSlider.Value
            self._grid:SetScale(min + math.pow(self._zoomSlider.Value, 2) * (max - min))

            function self._zoomSlider.OnValueChanged(slider, value)
                min = self._grid:GetMinScale()
                max = self._grid:GetMaxScale()
                self._grid:SetScale(min + math.pow(value, 2) * (max - min))
                self:GetScreen().Storage.ZoomSliderValue = value
            end
        end

        self._scanPowerLabel = sgui.Create(self, "label")
        self._scanPowerLabel.AlignX = TEXT_ALIGN_CENTER
        self._scanPowerLabel.AlignY = TEXT_ALIGN_CENTER
        self._scanPowerLabel:SetOrigin(self._grid:GetRight() + 16, 8)
        self._scanPowerLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
        self._scanPowerLabel.Text = "Scan Power"

        self._chargeSlider = sgui.Create(self, "slider")
        self._chargeSlider:SetOrigin(self._grid:GetRight() + 16, self._scanPowerLabel:GetBottom() + 8)
        self._chargeSlider:SetSize(self:GetWidth() * 0.4 - 16, 32)
        self._chargeSlider.CanClick = false
        self._chargeSlider.TextColorNeg = self._chargeSlider.TextColorPos
        self._chargeSlider.Value = self:GetSystem():GetCurrentCharge() / self:GetSystem():GetMaximumCharge()

        self._scanPowerBar = sgui.Create(self, "powerbar")
        self._scanPowerBar:SetOrigin(self._grid:GetRight() + 16, self._chargeSlider:GetBottom() + 8)
        self._scanPowerBar:SetSize(self:GetWidth() * 0.4 - 16, 32)

        self._scanButton = sgui.Create(self, "button")
        self._scanButton:SetOrigin(self._grid:GetRight() + 16, self._scanPowerBar:GetBottom() + 8)
        self._scanButton:SetSize(self:GetWidth() * 0.4 - 16, 48)
        self._scanButton.Text = "Scan"

        self._selectedLabel = sgui.Create(self, "label")
        self._selectedLabel.AlignX = TEXT_ALIGN_CENTER
        self._selectedLabel.AlignY = TEXT_ALIGN_CENTER
        self._selectedLabel:SetOrigin(self._grid:GetRight() + 16, self._scanButton:GetBottom() + 16)
        self._selectedLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
        self._selectedLabel.Text = "This Ship"

        self._inspectButton = sgui.Create(self, "button")
        self._inspectButton:SetOrigin(self._grid:GetRight() + 16, self._selectedLabel:GetBottom() + 8)
        self._inspectButton:SetSize(self:GetWidth() * 0.4 - 16, 48)
        self._inspectButton.Text = "Inspect"

        if SERVER then
            self._scanButton.OnClick = function(btn, button)
                self:GetSystem():StartScan()
                self:GetScreen():UpdateLayout()
                return true
            end

            self._inspectButton.OnClick = function(btn, button)
                if self._grid:GetCentreObject():GetObjectType() == objtype.ship then
                    self:Inspect(self._grid:GetCentreObject())
                    self:GetScreen():UpdateLayout()
                    return true
                end
                return false
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
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self:Inspect(nil)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.inspected = self._inspected
    end
elseif CLIENT then
    function GUI:Draw()
        if not self._inspected then
            local obj = self._grid:GetCentreObject()
            local x, y = obj:GetCoordinates()

            if obj ~= self:GetShip():GetObject() then
                self._selectedLabel.Text = obj:GetObjectName()
            else
                self._selectedLabel.Text = "This Ship"
            end
            self._coordLabel.Text = "x: " .. FormatNum(x, 1, 2) .. ", y: " .. FormatNum(y, 1, 2)
        end

        local dest = self:GetSystem():GetCurrentCharge() / self:GetSystem():GetMaximumCharge()
        self._chargeSlider.Value = self._chargeSlider.Value + (dest - self._chargeSlider.Value) * 0.1

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if self._inspected ~= layout.inspected then
            self:Inspect(layout.inspected)
        end

        local old = self._chargeSlider.Value

        self.Super[BASE].UpdateLayout(self, layout)

        self._chargeSlider.Value = old
        self._scanButton.CanClick = self:GetSystem():CanScan()

        if not self._inspected then
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

            self._inspectButton.CanClick = self._grid:GetCentreObject():GetObjectType() == objtype.ship
        end

    end
end
