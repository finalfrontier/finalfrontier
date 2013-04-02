local BASE = "page"

local ICON_SIZE = 48
local ICON_PADDING = 16

GUI.BaseName = BASE

GUI._shipview = nil
GUI._curroom = nil

GUI._closedshipheight = 0
GUI._openshipheight = 0

if CLIENT then
    GUI._changeroomtime = 0
end

GUI._roomelems = nil

function GUI:SetCurrentRoom(room)
    if CLIENT and ((room and not self._curroom)
        or (not room and self._curroom)) then
        self._changeroomtime = CurTime()
    end

    self._curroom = room

    if self._roomelems then
        for _, elem in pairs(self._roomelems) do
            elem:Remove()
        end
        self._roomelems = nil
    end

    if room then
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
            self._roomelems.slider.OnValueChanged = function(slider, value)
                self:GetSystem():SetSystemLimitRatio(system, value)
            end
        elseif CLIENT then
            self._roomelems.slider.GetValueText = function(slider, value)
                return FormatNum(self:GetSystem():GetTotalPower() * value, 1, 2) .. "kW"
            end
        end

        self._roomelems.needed = sgui.Create(self, "label")
        self._roomelems.needed:SetOrigin(self._roomelems.slider:GetRight() + ICON_PADDING, self._roomelems.icon:GetTop())
        self._roomelems.needed:SetSize(self:GetWidth() * 3 / 4 - self._roomelems.needed:GetLeft() - ICON_PADDING * 2 - ICON_SIZE, ICON_SIZE)

        self._roomelems.supplied = sgui.Create(self, "label")
        self._roomelems.supplied:SetOrigin(self._roomelems.needed:GetRight() + ICON_PADDING, self._roomelems.icon:GetTop())
        self._roomelems.supplied:SetSize(self:GetWidth() - self._roomelems.supplied:GetLeft() - ICON_PADDING * 2 - ICON_SIZE, ICON_SIZE)

        if CLIENT then
            self._roomelems.needed.AlignX = TEXT_ALIGN_RIGHT
            self._roomelems.needed.AlignY = TEXT_ALIGN_CENTER
            self._roomelems.needed.Text = "0"

            self._roomelems.supplied.AlignX = TEXT_ALIGN_RIGHT
            self._roomelems.supplied.AlignY = TEXT_ALIGN_CENTER
            self._roomelems.supplied.Text = "0"
        end

        self._roomelems.close = sgui.Create(self, "button")
        self._roomelems.close:SetOrigin(self:GetWidth() - ICON_PADDING - ICON_SIZE, self._roomelems.icon:GetTop())
        self._roomelems.close:SetSize(ICON_SIZE, ICON_SIZE)
        self._roomelems.close.Text = "X"

        if SERVER then
            function self._roomelems.close.OnClick(btn)
                self:SetCurrentRoom(nil)
            end
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
        room.CanClick = room:GetCurrentRoom():GetSystem() ~= nil and
            room:GetCurrentRoom():GetSystem().Powered

        if SERVER and room.CanClick then
            function room.OnClick(room)
                if self._curroom == room:GetCurrentRoom() then
                    self:SetCurrentRoom(nil)
                else
                    self:SetCurrentRoom(room:GetCurrentRoom())
                end
            end
        elseif CLIENT then
            function room.GetRoomColor(room)
                if room:GetCurrentRoom() == self._curroom then
                    return Color(48, 64, 32, 255)
                elseif room.CanClick then
                    return room.Color
                else
                    return Color(0, 0, 0, 255)
                end
            end
        end
    end

    self._closedshipheight = self:GetHeight() - ICON_PADDING * 1.5
    self._openshipheight = self:GetHeight() - ICON_PADDING * 2.5 - ICON_SIZE

    self._shipview:SetBounds(Bounds(
        ICON_PADDING,
        ICON_PADDING * 0.5,
        self:GetWidth() - ICON_PADDING * 2,
        self._closedshipheight
    ))
end

function GUI:Leave()
    self:SetCurrentRoom(nil)

    self.Super[BASE].Leave(self)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if self._curroom then
            layout.room = self._curroom:GetName()
            layout.needed = self._curroom:GetSystem():GetPowerNeeded()
        else
            layout.room = nil
        end
    end
elseif CLIENT then
    function GUI:Draw()
        local dt = (CurTime() - self._changeroomtime) / 0.125
        if dt >= 0 and dt <= 1 then
            if self._curroom then dt = 1 - dt end
            self._shipview:SetHeight(self._openshipheight
                + (self._closedshipheight - self._openshipheight) * dt)
        elseif self._curroom and self._shipview:GetHeight() ~= self._openshipheight then
            self._shipview:SetHeight(self._openshipheight)
        elseif not self._curroom and self._shipview:GetHeight() ~= self._closedshipheight then
            self._shipview:SetHeight(self._closedshipheight)
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if layout.room and (not self._curroom or
            self._curroom:GetName() ~= layout.room) then
            self:SetCurrentRoom(ships.GetRoomByName(layout.room))
        elseif self._curroom and not layout.room then
            self:SetCurrentRoom(nil)
        end

        if layout.room then
            self._roomelems.needed.Text = FormatNum(layout.needed, 1, 2) .. "kW"
            self._roomelems.supplied.Text = FormatNum(self._curroom:GetSystem():GetPower(), 1, 2) .. "kW"
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end
end
