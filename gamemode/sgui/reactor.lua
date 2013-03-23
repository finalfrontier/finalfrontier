local BASE = "page"

local ICON_SIZE = 48
local ICON_PADDING = 16

GUI.BaseName = BASE

GUI.Rows = nil

function GUI:AddRow(system)
    local row = {}
    row.Icon = sgui.Create(self, "image")
    row.Icon:SetOrigin(ICON_PADDING, ICON_PADDING + #self.Rows * (ICON_SIZE + ICON_PADDING))
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    if CLIENT then row.Icon.Material = system.Icon end

    row.Label = nil

    row.Slider = sgui.Create(self, "slider")
    row.Slider:SetOrigin(row.Icon:GetRight() + ICON_PADDING, row.Icon:GetTop())
    row.Slider:SetSize(self:GetWidth() - row.Slider:GetLeft() - ICON_PADDING, ICON_SIZE)
    if SERVER then
        row.Slider.Value = self:GetSystem():GetSystemWeight(system)
        row.Slider.OnValueChanged = function(slider, value)
            self:GetSystem():SetSystemWeight(system, value)
        end
    end

    table.insert(self.Rows, row)
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self.Rows = {}

    for _, room in pairs(self:GetShip():GetRooms()) do
        if room.System and room.System.Powered then
            self:AddRow(room.System)
        end
    end
end
