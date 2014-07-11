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

if SERVER then
    function GUI:_updateSliders()
        if self._roomelems and self._curroom then
            self._roomelems.atmoslider.Value = self:GetSystem():GetGoalAtmosphere(self._curroom)
            self._roomelems.tempslider.Value = self:GetSystem():GetGoalTemperature(self._curroom) / 600
        end
    end
end

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

        local totalWidth = self:GetWidth() - ICON_PADDING * 6 - ICON_SIZE
        local sliderWidth = totalWidth / 2 * 0.6
        local labelWidth = totalWidth / 2 * 0.4

        self._roomelems = {}
        self._roomelems.atmoslider = sgui.Create(self, "slider")
        self._roomelems.atmoslider.Color = Color(51, 172, 45, 191)
        self._roomelems.atmoslider:SetOrigin(ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
        self._roomelems.atmoslider:SetSize(sliderWidth, ICON_SIZE)
        if SERVER then
            function self._roomelems.atmoslider.OnValueChanged(slider, value)
                self:GetSystem():SetGoalAtmosphere(room, value)
            end
        elseif CLIENT then
            function self._roomelems.atmoslider.GetValueText(slider, value)
                if value < 0 then return "DISABLED" end
                return tostring(math.Round(value * 100)) .. "%"
            end
        end
        self._roomelems.atmolabel = sgui.Create(self, "label")
        self._roomelems.atmolabel:SetOrigin(self._roomelems.atmoslider:GetRight() + ICON_PADDING, self._roomelems.atmoslider:GetTop())
        self._roomelems.atmolabel:SetSize(labelWidth, ICON_SIZE)
        if CLIENT then
            self._roomelems.atmolabel.AlignX = TEXT_ALIGN_CENTER
            self._roomelems.atmolabel.AlignY = TEXT_ALIGN_CENTER
            self._roomelems.atmolabel.Text = ""
        end

        self._roomelems.tempslider = sgui.Create(self, "slider")
        self._roomelems.tempslider.Color = Color(172, 45, 51, 191)
        self._roomelems.tempslider:SetOrigin(self._roomelems.atmolabel:GetRight() + ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
        self._roomelems.tempslider:SetSize(sliderWidth, ICON_SIZE)
        self._roomelems.tempslider.Snap = 1 / 24
        if SERVER then
            function self._roomelems.tempslider.OnValueChanged(slider, value)
                self:GetSystem():SetGoalTemperature(room, value * 600)
            end
        elseif CLIENT then
            function self._roomelems.tempslider.GetValueText(slider, value)
                if value < 0 then return "DISABLED" end
                return tostring(math.Round(value * 600)) .. "K"
            end
        end
        self._roomelems.templabel = sgui.Create(self, "label")
        self._roomelems.templabel:SetOrigin(self._roomelems.tempslider:GetRight() + ICON_PADDING, self._roomelems.atmoslider:GetTop())
        self._roomelems.templabel:SetSize(labelWidth, ICON_SIZE)
        if CLIENT then
            self._roomelems.templabel.AlignX = TEXT_ALIGN_CENTER
            self._roomelems.templabel.AlignY = TEXT_ALIGN_CENTER
            self._roomelems.templabel.Text = ""
        end

        self._roomelems.close = sgui.Create(self, "button")
        self._roomelems.close:SetOrigin(self:GetWidth() - ICON_PADDING - ICON_SIZE, self._roomelems.atmoslider:GetTop())
        self._roomelems.close:SetSize(ICON_SIZE, ICON_SIZE)
        self._roomelems.close.Text = "X"

        if SERVER then
            self:_updateSliders()

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

    for _, room in ipairs(self._shipview:GetRoomElements()) do
        room.CanClick = true
        room.atmoDial = sgui.Create(self, "dualdial")
        room.tempDial = sgui.Create(self, "dualdial")

        if SERVER then
            function room.OnClick(room, x, y, button)
                if button == MOUSE1 and self._curroom == room:GetCurrentRoom() then
                    self:SetCurrentRoom(nil)
                elseif button == MOUSE1 then
                    self:SetCurrentRoom(room:GetCurrentRoom())
                else
                    if self:GetSystem():GetGoalAtmosphere(room:GetCurrentRoom()) < 0 or
                        self:GetSystem():GetGoalTemperature(room:GetCurrentRoom()) < 0 then
                        self:GetSystem():SetGoalAtmosphere(room:GetCurrentRoom(), 1.0)
                        self:GetSystem():SetGoalTemperature(room:GetCurrentRoom(), 300)
                    else
                        self:GetSystem():SetGoalAtmosphere(room:GetCurrentRoom(), -1)
                        self:GetSystem():SetGoalTemperature(room:GetCurrentRoom(), -1)
                    end

                    if room:GetCurrentRoom() == self:GetCurrentRoom() then
                        self:_updateSliders()
                    end
                end

                self:GetScreen():UpdateLayout()
                return true
            end

            room.atmoDial:SetTargetValue(math.max(self:GetSystem():GetGoalAtmosphere(room:GetCurrentRoom())))
            room.atmoDial:SetCurrentValue(room:GetCurrentRoom():GetAtmosphere())
            room.tempDial:SetTargetValue(math.max(0, self:GetSystem():GetGoalTemperature(room:GetCurrentRoom())) / 600)
            room.tempDial:SetCurrentValue(room:GetCurrentRoom():GetTemperature() / 600)
        elseif CLIENT then
            function room.GetRoomColor(room)
                if room:GetCurrentRoom() == self._curroom then
                    local glow = Pulse(0.5) * 32 + 32
                    return Color(glow, glow, glow, 255)
                else
                    return Color(32, 32, 32, 255)
                end
            end

            room.atmoDial:SetGlobalBounds(room:GetIconBounds())
            room.tempDial:SetGlobalBounds(room:GetIconBounds())

            local w, h = room.atmoDial:GetSize()

            room.atmoDial:SetSize(w * 2, h * 2)
            room.atmoDial:SetInnerRatio(0.625)
            room.atmoDial:SetCentre(room.atmoDial:GetLeft() + w / 2,
                room.atmoDial:GetTop() + h / 2)
            room.atmoDial.TargetColour = Color(51, 172, 45, 32)
            room.atmoDial.CurrentColour = Color(51, 172, 45, 127)
            
            room.tempDial:SetSize(w * 3, h * 3)
            room.tempDial:SetCentre(room.tempDial:GetLeft() + w / 2,
                room.tempDial:GetTop() + h / 2)
            room.tempDial.TargetColour = Color(172, 45, 51, 32)
            room.tempDial.CurrentColour = Color(172, 45, 51, 127)
        end
    end

    self._powerbar = nil

    self:SetCurrentRoom(nil)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        for _, room in ipairs(self._shipview:GetRoomElements()) do
            room.atmoDial:SetTargetValue(math.max(0, self:GetSystem():GetGoalAtmosphere(room:GetCurrentRoom())))
            room.tempDial:SetTargetValue(math.max(0, self:GetSystem():GetGoalTemperature(room:GetCurrentRoom())) / 600)
        end

        if self._curroom then
            layout.room = self._curroom:GetName()
        else
            layout.room = nil
        end

        self.Super[BASE].UpdateLayout(self, layout)
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
            self._roomelems.templabel.Text = FormatNum(self._curroom:GetTemperature(), 1, 1) .. "K"
            self._roomelems.atmolabel.Text = FormatNum(self._curroom:GetAtmosphere() * 100, 1, 1) .. "%"
        end

        self.Super[BASE].UpdateLayout(self, layout)

        for _, room in ipairs(self._shipview:GetRoomElements()) do
            if room.atmoDial and room.tempDial then
                room.atmoDial:SetCurrentValue(room:GetCurrentRoom():GetAtmosphere())
                room.tempDial:SetCurrentValue(room:GetCurrentRoom():GetTemperature() / 600)
            end
        end
    end
end
