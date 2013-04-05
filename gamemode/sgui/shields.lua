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
        self._roomelems = {}
        self._roomelems.slider = sgui.Create(self, "slider")
        self._roomelems.slider:SetOrigin(ICON_PADDING, self:GetHeight() - ICON_SIZE - ICON_PADDING)
        self._roomelems.slider:SetSize(self:GetWidth() / 2 - ICON_PADDING, ICON_SIZE)
        if SERVER then
            self._roomelems.slider.Value = self:GetSystem():GetDistrib(room)
            function self._roomelems.slider.OnValueChanged(slider, value)
                self:GetSystem():SetDistrib(room, value)
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

    for _, room in pairs(self._shipview:GetRoomElements()) do
        room.CanClick = true
        if SERVER then
            function room.OnClick(room)
                if self._curroom == room:GetCurrentRoom() then
                    self:SetCurrentRoom(nil)
                else
                    self:SetCurrentRoom(room:GetCurrentRoom())
                end
            end
        elseif CLIENT then
            function room.GetRoomColor(room)
                local clr = LerpColour(room.Color, Color(45, 51, 172, 255),
                    room:GetCurrentRoom():GetShields())
                if room:GetCurrentRoom() == self._curroom then
                    local glow = Pulse(0.5) * 32 + 32
                    return LerpColour(clr, Color(64, 64, 64, 255), Pulse(0.5) * 0.5 + 0.5)
                else
                    return clr
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

    self._powerbar = nil

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

        if layout.room then
            self._roomelems.supplied.Text = FormatNum(self._curroom:GetUnitShields(), 1, 2) 
                .. "kT / " .. FormatNum(self._curroom:GetSurfaceArea(), 1, 2) .. "kT"
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end
end
