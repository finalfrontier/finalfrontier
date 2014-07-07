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

GUI._grid = nil
GUI._zoomLabel = nil
GUI._zoomSlider = nil
GUI._sectorLabel = nil
GUI._coordLabel = nil
GUI._angleLabel = nil
GUI._powerBar = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._grid = sgui.Create(self, "sectorgrid")
    self._grid:SetOrigin(8, 8)
    self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 16)
    self._grid:SetCentreObject(nil)
    self._grid:SetInitialScale(self._grid:GetMinScale())

    if SERVER then
        function self._grid.OnClick(grid, x, y, button)
            if button == MOUSE1 then
                local sx, sy = self:GetShip():GetCoordinates()
                local tx, ty = grid:ScreenToCoordinate(x - grid:GetLeft(), y - grid:GetTop())
                local dx, dy = universe:GetDifference(sx, sy, tx, ty)

                self:GetSystem():SetTargetHeading(dx, dy)
            elseif button == MOUSE2 then
                self:GetSystem():FullStop()
            end
            return true
        end
    end

    local colLeft = self._grid:GetRight() + 16
    local colWidth = self:GetWidth() * 0.4 - 16

    self._zoomLabel = sgui.Create(self, "label")
    self._zoomLabel.AlignX = TEXT_ALIGN_CENTER
    self._zoomLabel.AlignY = TEXT_ALIGN_CENTER
    self._zoomLabel:SetOrigin(colLeft, 16)
    self._zoomLabel:SetSize(colWidth, 32)
    self._zoomLabel.Text = "View Zoom"

    self._zoomSlider = sgui.Create(self, "slider")
    self._zoomSlider:SetOrigin(colLeft, self._zoomLabel:GetBottom() + 8)
    self._zoomSlider:SetSize(colWidth, 48)

    if SERVER then
        self._zoomSlider.Value = self._grid:GetScaleRatio()

        function self._zoomSlider.OnValueChanged(slider, value)
            self._grid:SetScaleRatio(value)
        end
    end

    self._sectorLabel = sgui.Create(self, "label")
    self._sectorLabel.AlignX = TEXT_ALIGN_CENTER
    self._sectorLabel.AlignY = TEXT_ALIGN_CENTER
    self._sectorLabel:SetOrigin(colLeft, self._zoomSlider:GetBottom() + 32)
    self._sectorLabel:SetSize(colWidth, 32)

    self._coordLabel = sgui.Create(self, "label")
    self._coordLabel.AlignX = TEXT_ALIGN_CENTER
    self._coordLabel.AlignY = TEXT_ALIGN_CENTER
    self._coordLabel:SetOrigin(colLeft, self._sectorLabel:GetBottom() + 16)
    self._coordLabel:SetSize(colWidth, 32)

    self._angleLabel = sgui.Create(self, "label")
    self._angleLabel.AlignX = TEXT_ALIGN_CENTER
    self._angleLabel.AlignY = TEXT_ALIGN_CENTER
    self._angleLabel:SetOrigin(colLeft, self._coordLabel:GetBottom() + 16)
    self._angleLabel:SetSize(colWidth, 32)

    self._powerBar = sgui.Create(self, "powerbar")
    self._powerBar:SetOrigin(colLeft, self:GetHeight() - 64)
    self._powerBar:SetSize(colWidth, 48)
end

if CLIENT then
    function GUI:Draw()
        local sx, sy = self:GetShip():GetCoordinates()
        self._coordLabel.Text = "x: " .. FormatNum(sx, 1, 2) .. ", y: " .. FormatNum(sy, 1, 2)
        self._angleLabel.Text = "bearing: " .. FormatBearing(self:GetShip():GetRotation())

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
