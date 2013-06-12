local BASE = "page"

GUI.BaseName = BASE

GUI._inspected = nil
GUI._oldScale = 0

GUI._zoomLabel = nil
GUI._zoomSlider = nil
GUI._selectedLabel = nil
GUI._inspectButton = nil
GUI._coordLabel = nil
GUI._sectorLabel = nil
GUI._grid = nil

GUI._shipView = nil
GUI._closeButton = nil

if SERVER then
    function GUI:CanTeleportEntity(ent)
        return IsValid(ent) and (ent:IsPlayer(ent) or ent:GetClass() == "prop_physics")
    end

    local warmupSounds = {
        "ambient/levels/citadel/zapper_warmup1.wav",
        "ambient/levels/citadel/zapper_warmup4.wav"
    }

    local failedSounds = {
        "ambient/energy/zap7.wav",
        "ambient/energy/zap8.wav"
    }

    local transmitSounds = {
        "ambient/machines/teleport1.wav",
        "ambient/machines/teleport3.wav",
        "ambient/machines/teleport4.wav"
    }

    local receiveSounds = {
        "ambient/levels/labs/electric_explosion1.wav",
        "ambient/levels/labs/electric_explosion2.wav",
        "ambient/levels/labs/electric_explosion3.wav",
        "ambient/levels/labs/electric_explosion4.wav"
    }

    function GUI:StartTeleport(room)
        sound.Play(table.Random(warmupSounds), self:GetScreen():GetPos(), 100, 70)

        timer.Simple(2.5, function()
            for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
                for _, ent in pairs(ents.FindInSphere(pad, 64)) do
                    if self:TeleportEntity(ent, room) then
                        return
                    end
                end
            end

            for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
                sound.Play(table.Random(failedSounds), pad, 70, 110)
            end
        end)
    end

    function GUI:TeleportEntity(ent, room)
        if not self:CanTeleportEntity(ent) then return false end

        local oldpos = ent:GetPos()
        local newpos = room:GetTransporterTarget()

        ent:SetPos(newpos)

        if ent:IsPlayer() then
            local ship = ships.FindCurrentShip(ent)
            if ship then ent:SetShip(ship) end
        else
            local phys = ent:GetPhysicsObject()
            if phys and IsValid(phys) then
                phys:Wake()
            end
        end

        sound.Play(table.Random(transmitSounds), oldpos, 75, 100 + math.random() * 20)
        sound.Play(table.Random(receiveSounds), newpos, 85, 100 + math.random() * 20)

        local ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(oldpos)
        util.Effect("entity_remove", ed, true, true)

        ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(newpos)
        util.Effect("propspawn", ed, true, true)

        ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(newpos)
        util.Effect("entity_remove", ed, true, true)

        return true
    end
end

function GUI:Inspect(obj)
    self:RemoveAllChildren()
    if obj then
        self._inspected = obj
        self._oldScale = self._grid:GetScale()

        self._zoomLabel = nil
        self._zoomSlider = nil
        self._selectedLabel = nil
        self._inspectButton = nil
        self._coordLabel = nil
        self._sectorLabel = nil
        self._grid = nil

        self._shipView = sgui.Create(self, "shipview")
        self._shipView:SetCurrentShip(ships.GetByName(obj:GetObjectName()))
        self._shipView:SetBounds(Bounds(16, 8, self:GetWidth() - 32, self:GetHeight() - 88))
        self._shipView:SetCanClickRooms(true)

        if SERVER then
            self._shipView:SetRoomOnClickHandler(function(room, x, y, button)
                self:StartTeleport(room:GetCurrentRoom())
            end)
        end

        self._closeButton = sgui.Create(self, "button")
        self._closeButton:SetOrigin(16, self:GetHeight() - 48 - 16)
        self._closeButton:SetSize(self:GetWidth() - 32, 48)
        self._closeButton.Text = "Return to Sector View"

        if SERVER then
            function self._closeButton.OnClick(btn, x, y, button)
                self:Inspect(nil)
                self._grid:SetCentreObject(obj)
                self:GetScreen():UpdateLayout()
            end
        end
    else
        self._inspected = nil
        self._shipView = nil
        self._closeButton = nil

        self._grid = sgui.Create(self, "sectorgrid")
        self._grid:SetOrigin(8, 8)
        self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 16)
        self._grid:SetCentreObject(nil)
        self._grid:SetScale(math.max(self._grid:GetMinSensorScale(), self._oldScale))

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
            local min = self._grid:GetMinScale()
            local max = self._grid:GetMaxScale()
            self._zoomSlider.Value = math.sqrt((self._grid:GetScale() - min) / (max - min))
            function self._zoomSlider.OnValueChanged(slider, value)
                min = self._grid:GetMinScale()
                max = self._grid:GetMaxScale()
                self._grid:SetScale(min + math.pow(value, 2) * (max - min))
            end
        end

        self._selectedLabel = sgui.Create(self, "label")
        self._selectedLabel.AlignX = TEXT_ALIGN_CENTER
        self._selectedLabel.AlignY = TEXT_ALIGN_CENTER
        self._selectedLabel:SetOrigin(self._grid:GetRight() + 16, self._zoomSlider:GetBottom() + 48)
        self._selectedLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
        self._selectedLabel.Text = "This Ship"

        self._inspectButton = sgui.Create(self, "button")
        self._inspectButton:SetOrigin(self._grid:GetRight() + 16, self._selectedLabel:GetBottom() + 8)
        self._inspectButton:SetSize(self:GetWidth() * 0.4 - 16, 48)
        self._inspectButton.Text = "Inspect"

        if SERVER then
            self._inspectButton.OnClick = function(btn, button)
                if self._grid:GetCentreObject():GetObjectType() == objtype.ship then
                    self:Inspect(self._grid:GetCentreObject())
                    self:GetScreen():UpdateLayout()
                end
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

            self._selectedLabel.Text = obj:GetObjectName()
            self._coordLabel.Text = "x: " .. FormatNum(x, 1, 2) .. ", y: " .. FormatNum(y, 1, 2)
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if self._inspected ~= layout.inspected then
            self:Inspect(layout.inspected)
        end

        self.Super[BASE].UpdateLayout(self, layout)

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


