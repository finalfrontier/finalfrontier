local BASE = "page"

local ICON_SIZE = 48
local ICON_PADDING = 16

GUI.BaseName = BASE

GUI.Rows = nil

function GUI:AddRow(system)
    local row = {}
    row.Icon = sgui.Create(self, "image")
    row.Icon:SetOrigin(8, ICON_PADDING + #self.Rows * (ICON_SIZE + ICON_PADDING))
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    if CLIENT then row.Icon.Material = system.Icon end

    row.Label = nil
    row.Slider = nil

    table.insert(self.Rows, row)
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self.Rows = {}

    for _, room in pairs(self:GetShip():GetRooms()) do
        if room.System then
            self:AddRow(room.System)
        end
    end
end
