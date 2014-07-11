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
GUI._powerbar = nil

function GUI:GetCurrentRoom()
    return self._curroom
end

function GUI:SetCurrentRoom(room)
    self._curroom = room

    if self._roomelems then
        for _, elem in pairs(self._roomelems) do
            elem:Remove()
        end
        self._roomelems = nil
    end

    if room then
        if self._powerbar then
            self._powerbar:Remove()
            self._powerbar = nil
        end
        self._roomelems = {}
        self._roomelems.slider = sgui.Create(self, "slider")
        self._roomelems.slider:SetOrigin(ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
        self._roomelems.slider:SetSize(self:GetWidth() / 2 - ICON_PADDING, ICON_SIZE)
        self._roomelems.slider.Color = Color(45, 51, 172, 191)
        if SERVER then
            self._roomelems.slider.Value = self:GetSystem():GetDistrib(room)
            function self._roomelems.slider.OnValueChanged(slider, value)
                self:GetSystem():SetDistrib(room, value)
                self:GetScreen():UpdateLayout()
            end
        end
        self._roomelems.supplied = sgui.Create(self, "label")
        self._roomelems.supplied:SetOrigin(self._roomelems.slider:GetRight() + ICON_PADDING, self._roomelems.slider:GetTop())
        self._roomelems.supplied:SetSize(self:GetWidth() - self._roomelems.supplied:GetLeft() - ICON_PADDING * 2 - ICON_SIZE, ICON_SIZE)

        if CLIENT then
            self._roomelems.supplied.AlignX = TEXT_ALIGN_CENTER
            self._roomelems.supplied.AlignY = TEXT_ALIGN_CENTER
            self._roomelems.supplied.Text = ""
        end

        self._roomelems.close = sgui.Create(self, "button")
        self._roomelems.close:SetOrigin(self:GetWidth() - ICON_PADDING - ICON_SIZE, self._roomelems.slider:GetTop())
        self._roomelems.close:SetSize(ICON_SIZE, ICON_SIZE)
        self._roomelems.close.Text = "X"

        if SERVER then
            function self._roomelems.close.OnClick(btn)
                self:SetCurrentRoom(nil)
                return true
            end
        end
    else
        if not self._powerbar then
            self._powerbar = sgui.Create(self, "powerbar")
            self._powerbar:SetOrigin(ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
            self._powerbar:SetSize(self:GetWidth() - ICON_PADDING * 2, ICON_SIZE)
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

    self._shipview:SetBounds(Bounds(
        ICON_PADDING,
        ICON_PADDING * 0.5,
        self:GetWidth() - ICON_PADDING * 2,
        self:GetHeight() - ICON_PADDING * 2.5 - ICON_SIZE
    ))

    for _, room in pairs(self._shipview:GetRoomElements()) do
        room.CanClick = true
        room.shieldDial = sgui.Create(self, "dualdial")

        if SERVER then
            function room.OnClick(room)
                if self._curroom == room:GetCurrentRoom() then
                    self:SetCurrentRoom(nil)
                else
                    self:SetCurrentRoom(room:GetCurrentRoom())
                end
                return true
            end

            room.shieldDial:SetTargetValue(self:GetSystem():GetDistrib(room:GetCurrentRoom()))
            room.shieldDial:SetCurrentValue(room:GetCurrentRoom():GetUnitShields() / room:GetCurrentRoom():GetSurfaceArea())
        elseif CLIENT then
            function room.GetRoomColor(room)
                if room:GetCurrentRoom() == self._curroom then
                    local glow = Pulse(0.5) * 32 + 32
                    return Color(glow, glow, glow, 255)
                else
                    return Color(32, 32, 32, 255)
                end
            end

            room.shieldDial:SetGlobalBounds(room:GetIconBounds())

            local w, h = room.shieldDial:GetSize()

            room.shieldDial:SetSize(w * 2, h * 2)
            room.shieldDial:SetInnerRatio(0.625)
            room.shieldDial:SetCentre(room.shieldDial:GetLeft() + w / 2,
                room.shieldDial:GetTop() + h / 2)
            room.shieldDial.TargetColour = Color(45, 51, 172, 32)
            room.shieldDial.CurrentColour = Color(45, 51, 172, 127)
        end
    end

    self._powerbar = nil

    self:SetCurrentRoom(nil)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        for _, room in pairs(self._shipview:GetRoomElements()) do
            room.shieldDial:SetTargetValue(self:GetSystem():GetDistrib(room:GetCurrentRoom()))
        end

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

        if layout.room then
            self._roomelems.supplied.Text = FormatNum(self._curroom:GetUnitShields(), 1, 2) 
                .. "kT / " .. FormatNum(self._curroom:GetSurfaceArea(), 1, 2) .. "kT"
        end

        self.Super[BASE].UpdateLayout(self, layout)

        for _, room in pairs(self._shipview:GetRoomElements()) do
            if room.shieldDial then
                room.shieldDial:SetCurrentValue(room:GetCurrentRoom():GetUnitShields() / room:GetCurrentRoom():GetSurfaceArea())
            end
        end
    end
end
