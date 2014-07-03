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

local ICON_SIZE = 48
local ICON_PADDING = 16

GUI.BaseName = BASE

GUI._shipview = nil
GUI._curroom = nil

GUI._roomelems = nil
GUI._totalbar = nil
GUI._totaltext = nil

function GUI:SetCurrentRoom(room)
    self._curroom = room

    if self._roomelems then
        for _, elem in pairs(self._roomelems) do
            elem:Remove()
        end
        self._roomelems = nil
    end

    if room then
        if self._totalbar then
            self._totalbar:Remove()
            self._totaltext:Remove()
            self._totalbar = nil
            self._totaltext = nil
        end

        local system = room:GetSystem()

        self._roomelems = {}
        self._roomelems.icon = sgui.Create(self, "image")
        self._roomelems.icon:SetOrigin(ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
        self._roomelems.icon:SetSize(ICON_SIZE, ICON_SIZE)
        if CLIENT then self._roomelems.icon.Material = system.Icon end

        self._roomelems.slider = sgui.Create(self, "slider")
        self._roomelems.slider:SetOrigin(self._roomelems.icon:GetRight() + ICON_PADDING, self._roomelems.icon:GetTop())
        self._roomelems.slider:SetSize(self:GetWidth() / 2 - self._roomelems.slider:GetLeft() - ICON_PADDING, ICON_SIZE)
        if SERVER then
            self._roomelems.slider.Value = self:GetSystem():GetSystemLimitRatio(system)
            function self._roomelems.slider.OnValueChanged(slider, value)
                self:GetSystem():SetSystemLimitRatio(system, value)
            end
        elseif CLIENT then
            function self._roomelems.slider.GetValueText(slider, value)
                return FormatNum(self:GetSystem():GetTotalPower() * value, 1, 2) .. "MW"
            end
        end
        self._roomelems.supplied = sgui.Create(self, "label")
        self._roomelems.supplied:SetOrigin(self._roomelems.slider:GetRight() + ICON_PADDING, self._roomelems.icon:GetTop())
        self._roomelems.supplied:SetSize(self:GetWidth() - self._roomelems.supplied:GetLeft() - ICON_PADDING * 2 - ICON_SIZE, ICON_SIZE)

        if CLIENT then
            self._roomelems.supplied.AlignX = TEXT_ALIGN_CENTER
            self._roomelems.supplied.AlignY = TEXT_ALIGN_CENTER
            self._roomelems.supplied.Text = ""
        end

        self._roomelems.close = sgui.Create(self, "button")
        self._roomelems.close:SetOrigin(self:GetWidth() - ICON_PADDING - ICON_SIZE, self._roomelems.icon:GetTop())
        self._roomelems.close:SetSize(ICON_SIZE, ICON_SIZE)
        self._roomelems.close.Text = "X"

        if SERVER then
            function self._roomelems.close.OnClick(btn)
                self:SetCurrentRoom(nil)
                return true
            end
        end
    else
        if not self._totalbar then
            self._totalbar = sgui.Create(self, "slider")
            self._totalbar:SetOrigin(ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
            self._totalbar:SetSize(self:GetWidth() - ICON_PADDING * 2, ICON_SIZE)
            self._totalbar.CanClick = false

            local total = self:GetSystem():GetTotalPower()
            if total > 0 then
                self._totalbar.Value = math.min(1, self:GetSystem():GetTotalNeeded() / total)
            else
                self._totalbar.Value = 0
            end

            self._totaltext = sgui.Create(self, "label")
            self._totaltext:SetBounds(self._totalbar:GetBounds())
            if CLIENT then
                function self._totalbar.GetValueText(slider, value)
                    return ""
                end

                self._totaltext.AlignX = TEXT_ALIGN_CENTER
                self._totaltext.AlignY = TEXT_ALIGN_CENTER
                self._totaltext.Text = ""
            end
        end
    end

    if SERVER then
        self:GetScreen():UpdateLayout()
    end
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._shipview = sgui.Create(self, "shipview")
    self._shipview:SetCurrentShip(self:GetShip())

    for _, room in pairs(self._shipview:GetRoomElements()) do
        room.CanClick = room:GetCurrentRoom():GetSystem() ~= nil and
            room:GetCurrentRoom():GetSystem().Powered

        if SERVER and room.CanClick then
            function room.OnClick(room)
                if self._curroom == room:GetCurrentRoom() then
                    self:SetCurrentRoom(nil)
                else
                    self:SetCurrentRoom(room:GetCurrentRoom())
                end
                return true
            end
        elseif CLIENT then
            function room.GetRoomColor(room)
                if room:GetCurrentRoom() == self._curroom then
                    local glow = Pulse(0.5) * 32 + 32
                    return Color(glow, glow, glow, 255)
                elseif room.CanClick then
                    return room.Color
                else
                    return Color(0, 0, 0, 255)
                end
            end
        end
    end

    self._shipview:SetBounds(Bounds(
        ICON_PADDING,
        ICON_PADDING * 0.5,
        self:GetWidth() - ICON_PADDING * 2,
        self:GetHeight() - ICON_PADDING * 2.5 - ICON_SIZE
    ))

    self._totalbar = nil

    self:SetCurrentRoom(nil)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if self._curroom then
            layout.room = self._curroom:GetName()
        else
            layout.room = nil
        end
    end
elseif CLIENT then
    function GUI:UpdateLayout(layout)
        if layout.room and (not self._curroom or
            self._curroom:GetName() ~= layout.room) then
            self:SetCurrentRoom(ships.GetRoomByName(layout.room))
        elseif self._curroom and not layout.room then
            self:SetCurrentRoom(nil)
        end

        self.Super[BASE].UpdateLayout(self, layout)

        if layout.room then
            self._roomelems.supplied.Text = FormatNum(self._curroom:GetSystem():GetPower(), 1, 2) 
                .. "MW / " .. FormatNum(self._curroom:GetSystem():GetPowerNeeded(), 1, 2) .. "MW"
        else
            self._totaltext.Text = FormatNum(self:GetSystem():GetTotalNeeded(), 1, 2) .. "MW / "
                .. FormatNum(self:GetSystem():GetTotalPower(), 1, 2) .. "MW"
                
            local total = self:GetSystem():GetTotalPower()
            if total > 0 then
                self._totalbar.Value = math.min(1, self:GetSystem():GetTotalNeeded() / total)
            else
                self._totalbar.Value = 0
            end
        end
    end
end
