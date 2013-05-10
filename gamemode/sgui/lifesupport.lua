local BASE = "page"

local ICON_SIZE = 48
local ICON_PADDING = 16

GUI.BaseName = BASE

GUI._shipview = nil
GUI._curroom = nil

GUI._roomelems = nil
GUI._powerbar = nil

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
            self._roomelems.atmoslider.Value = self:GetSystem():GetGoalAtmosphere(room)
            function self._roomelems.atmoslider.OnValueChanged(slider, value)
                self:GetSystem():SetGoalAtmosphere(room, value)
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
            self._roomelems.tempslider.Value = self:GetSystem():GetGoalTemperature(room) / 600
            function self._roomelems.tempslider.OnValueChanged(slider, value)
                self:GetSystem():SetGoalTemperature(room, value * 600)
            end
        elseif CLIENT then
            function self._roomelems.tempslider.GetValueText(slider, value)
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
            function self._roomelems.close.OnClick(btn)
                self:SetCurrentRoom(nil)
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
        self.Screen:UpdateLayout()
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
            function room.OnClick(room)
                if self._curroom == room:GetCurrentRoom() then
                    self:SetCurrentRoom(nil)
                else
                    self:SetCurrentRoom(room:GetCurrentRoom())
                end
            end

            room.atmoDial:SetTargetValue(self:GetSystem():GetGoalAtmosphere(room:GetCurrentRoom()))
            room.atmoDial:SetCurrentValue(room:GetCurrentRoom():GetAtmosphere())
            room.tempDial:SetTargetValue(self:GetSystem():GetGoalTemperature(room:GetCurrentRoom()) / 600)
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
            room.atmoDial:SetTargetValue(self:GetSystem():GetGoalAtmosphere(room:GetCurrentRoom()))
            room.tempDial:SetTargetValue(self:GetSystem():GetGoalTemperature(room:GetCurrentRoom()) / 600)
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
            -- TODO update current atmo / temp
        end

        self.Super[BASE].UpdateLayout(self, layout)

        for _, room in ipairs(self._shipview:GetRoomElements()) do
            room.atmoDial:SetCurrentValue(room:GetCurrentRoom():GetAtmosphere())
            room.tempDial:SetCurrentValue(room:GetCurrentRoom():GetTemperature() / 600)
        end
    end
end
