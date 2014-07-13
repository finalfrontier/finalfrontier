-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

local BASE = "page"

GUI.BaseName = BASE

GUI._inspected = nil

GUI._zoomLabel = nil
GUI._zoomSlider = nil
GUI._selectedLabel = nil
GUI._inspectButton = nil
GUI._jettisonButton = nil
GUI._chargeSlider = nil
GUI._powerBar = nil
GUI._grid = nil

GUI._shipView = nil
GUI._closeButton = nil

function GUI:Inspect(obj)
    if not self:GetSystem() then return end

    self:RemoveAllChildren()

    local colWidth = self:GetWidth() * 0.4 - 16

    if obj then
        self._inspected = obj

        self._zoomLabel = nil
        self._zoomSlider = nil
        self._selectedLabel = nil
        self._inspectButton = nil
        self._jettisonButton = nil
        self._coordLabel = nil
        self._sectorLabel = nil
        self._grid = nil

        self._shipView = sgui.Create(self, "shipview")
        self._shipView:SetCurrentShip(ships.GetByName(obj:GetObjectName()))
        self._shipView:SetBounds(Bounds(16, 8, self:GetWidth() - 32, self:GetHeight() - 88))
        self._shipView:SetCanClickRooms(true)

        if SERVER then
            self._shipView:SetRoomOnClickHandler(function(room, x, y, button)
                self:GetSystem():StartTeleport(room:GetCurrentRoom())
                return true
            end)
        elseif CLIENT then
            if obj ~= self:GetShip():GetObject() then
                self._shipView:SetRoomColourFunction(function(room)
                    if room:GetCurrentRoom():GetShields() >= self:GetSystem():GetShieldThreshold() then
                        return Color(64, 32, 32, 255)
                    else
                        return room.Color
                    end
                end)
            end
        end

        self._closeButton = sgui.Create(self, "button")
        self._closeButton:SetOrigin(16, self:GetHeight() - 48 - 16)
        self._closeButton:SetSize(self:GetWidth() - 56 - colWidth * 2, 48)
        self._closeButton.Text = "Back"

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
        self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 16)
        self._grid:SetCentreObject(nil)
        self._grid:SetInitialScale(self._grid:GetMinSensorScale())

        if SERVER then
            function self._grid.OnClickSelectedObject(grid, obj, button)
                if obj:GetObjectType() == objtype.SHIP then
                    self:Inspect(obj)
                    self:GetScreen():UpdateLayout()
                    return true
                elseif obj:GetObjectType() == objtype.MODULE then
                    self:GetSystem():StartTeleport(obj)
                end
                return false
            end
        end

        self._zoomLabel = sgui.Create(self, "label")
        self._zoomLabel.AlignX = TEXT_ALIGN_CENTER
        self._zoomLabel.AlignY = TEXT_ALIGN_CENTER
        self._zoomLabel:SetOrigin(self._grid:GetRight() + 16, 16)
        self._zoomLabel:SetSize(colWidth, 32)
        self._zoomLabel.Text = "View Zoom"

        self._zoomSlider = sgui.Create(self, "slider")
        self._zoomSlider:SetOrigin(self._grid:GetRight() + 16, self._zoomLabel:GetBottom() + 8)
        self._zoomSlider:SetSize(colWidth, 48)

        if SERVER then
            self._zoomSlider.Value = self._grid:GetScaleRatio()

            function self._zoomSlider.OnValueChanged(slider, value)
                self._grid:SetScaleRatio(value)
            end
        end

        self._selectedLabel = sgui.Create(self, "label")
        self._selectedLabel.AlignX = TEXT_ALIGN_CENTER
        self._selectedLabel.AlignY = TEXT_ALIGN_CENTER
        self._selectedLabel:SetOrigin(self._grid:GetRight() + 16, self._zoomSlider:GetBottom() + 16)
        self._selectedLabel:SetSize(colWidth, 32)
        self._selectedLabel.Text = "This Ship"

        self._inspectButton = sgui.Create(self, "button")
        self._inspectButton:SetOrigin(self._grid:GetRight() + 16, self._selectedLabel:GetBottom() + 8)
        self._inspectButton:SetSize(colWidth, 48)
        self._inspectButton.Text = "Select Room"

        if SERVER then
            self._inspectButton.OnClick = function(btn, button)
                local obj = self._grid:GetCentreObject()
                if obj:GetObjectType() == objtype.SHIP then
                    self:Inspect(obj)
                    self:GetScreen():UpdateLayout()
                    return true
                elseif obj:GetObjectType() == objtype.MODULE then
                    self:GetSystem():StartTeleport(obj)
                    return true
                end
                return false
            end
        end

        self._jettisonButton = sgui.Create(self, "button")
        self._jettisonButton:SetOrigin(self._grid:GetRight() + 16, self._inspectButton:GetBottom() + 8)
        self._jettisonButton:SetSize(colWidth, 48)
        self._jettisonButton.Text = "Jettison"

        if SERVER then
            self._jettisonButton.OnClick = function(btn, button)
                self:GetSystem():StartTeleport(nil)
                return true
            end
        end
    end

    self._chargeSlider = sgui.Create(self, "slider")
    self._chargeSlider:SetSize(colWidth, 48)
    self._chargeSlider.CanClick = false
    self._chargeSlider.TextColorNeg = self._chargeSlider.TextColorPos
    self._chargeSlider.Value = self:GetSystem():GetCurrentCharge() / self:GetSystem():GetMaximumCharge()

    if CLIENT then
        function self._chargeSlider.GetValueText(slider, value)
            return FormatNum(value * self:GetSystem():GetMaximumCharge(), 1, 2) .. "MC"
        end
    end

    self._powerBar = sgui.Create(self, "powerbar")
    self._powerBar:SetSize(colWidth, 48)

    if obj then
        self._chargeSlider:SetOrigin(self._closeButton:GetRight() + 16, self._closeButton:GetTop())
        self._powerBar:SetOrigin(self._chargeSlider:GetRight() + 8, self._closeButton:GetTop())
    else
        self._powerBar:SetOrigin(self._grid:GetRight() + 16, self:GetHeight() - 56)
        self._chargeSlider:SetOrigin(self._grid:GetRight() + 16, self._powerBar:GetTop() - 56)
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
        if self:GetSystem() then
            if self._grid then
                local obj = self._grid:GetCentreObject()
                if IsValid(obj) then
                    self._selectedLabel.Text = obj:GetDescription()
                else
                    self._selectedLabel.Text = "Select Target"
                end
            end

            local dest = self:GetSystem():GetCurrentCharge() / self:GetSystem():GetMaximumCharge()

            self._chargeSlider.Value = self._chargeSlider.Value + (dest - self._chargeSlider.Value) * 0.1
        end 

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if self._inspected ~= layout.inspected then
            self:Inspect(layout.inspected)
        end

        local old = self._chargeSlider.Value

        self.Super[BASE].UpdateLayout(self, layout)

        self._chargeSlider.Value = old

        if self._grid then
            local obj = self._grid:GetCentreObject()
            self._inspectButton.CanClick = obj and (
                obj:GetObjectType() == objtype.SHIP or
                self:GetSystem():IsObjectTeleportable(obj))

            if obj and self:GetSystem():IsObjectTeleportable(obj) then
                self._inspectButton.Text = "Teleport In"
            else
                self._inspectButton.Text = "Select Room"
            end
        end
    end
end
