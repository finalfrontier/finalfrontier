local BASE = "page"

local ICON_SIZE = 48
local ICON_PADDING = 16

GUI.BaseName = BASE

GUI.Rows = nil

function GUI:AddRow(system)
    local row = {}
    row.System = system

    row.Icon = sgui.Create(self, "image")
    row.Icon:SetOrigin(ICON_PADDING, ICON_PADDING + (#self.Rows + 1) * (ICON_SIZE + ICON_PADDING))
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    if CLIENT then row.Icon.Material = system.Icon end

    row.Slider = sgui.Create(self, "slider")
    row.Slider:SetOrigin(row.Icon:GetRight() + ICON_PADDING, row.Icon:GetTop())
    row.Slider:SetSize(self:GetWidth() / 2 - row.Slider:GetLeft() - ICON_PADDING, ICON_SIZE)
    if SERVER then
        row.Slider.Value = self:GetSystem():GetSystemLimitRatio(system)
        row.Slider.OnValueChanged = function(slider, value)
            self:GetSystem():SetSystemLimitRatio(system, value)
        end
    elseif CLIENT then
        row.Slider.GetValueText = function(slider, value)
            return FormatNum(self:GetSystem():GetTotalPower() * value, 1, 2) .. "kW"
        end
    end

    row.Needed = sgui.Create(self, "label")
    row.Needed:SetOrigin(row.Slider:GetRight() + ICON_PADDING, row.Icon:GetTop())
    row.Needed:SetSize(self:GetWidth() * 3 / 4 - row.Needed:GetLeft() - ICON_PADDING, ICON_SIZE)

    row.Limit = sgui.Create(self, "label")
    row.Limit:SetOrigin(row.Needed:GetRight() + ICON_PADDING, row.Icon:GetTop())
    row.Limit:SetSize(self:GetWidth() - row.Limit:GetLeft() - ICON_PADDING, ICON_SIZE)

    if CLIENT then
        row.Needed.AlignX = TEXT_ALIGN_RIGHT
        row.Needed.AlignY = TEXT_ALIGN_CENTER
        row.Needed.Text = "0"

        row.Limit.AlignX = TEXT_ALIGN_RIGHT
        row.Limit.AlignY = TEXT_ALIGN_CENTER
        row.Limit.Text = "0"
    end

    table.insert(self.Rows, row)
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    local limitLabel = sgui.Create(self, "label")
    limitLabel:SetOrigin(ICON_PADDING * 2 + ICON_SIZE, ICON_PADDING)
    limitLabel:SetSize(self:GetWidth() / 2 - limitLabel:GetLeft() - ICON_PADDING, ICON_SIZE)

    local neededLabel = sgui.Create(self, "label")
    neededLabel:SetOrigin(limitLabel:GetRight() + ICON_PADDING, ICON_PADDING)
    neededLabel:SetSize(self:GetWidth() * 3 / 4 - neededLabel:GetLeft() - ICON_PADDING, ICON_SIZE)

    local suppliedLabel = sgui.Create(self, "label")
    suppliedLabel:SetOrigin(neededLabel:GetRight() + ICON_PADDING, ICON_PADDING)
    suppliedLabel:SetSize(self:GetWidth() - suppliedLabel:GetLeft() - ICON_PADDING, ICON_SIZE)

    if CLIENT then
        limitLabel.AlignX = TEXT_ALIGN_CENTER
        limitLabel.AlignY = TEXT_ALIGN_CENTER
        limitLabel.Text = "POWER LIMIT"

        neededLabel.AlignX = TEXT_ALIGN_CENTER
        neededLabel.AlignY = TEXT_ALIGN_CENTER
        neededLabel.Text = "NEEDED"

        suppliedLabel.AlignX = TEXT_ALIGN_CENTER
        suppliedLabel.AlignY = TEXT_ALIGN_CENTER
        suppliedLabel.Text = "SUPPLIED"
    end

    self.Rows = {}

    for _, room in pairs(self:GetShip():GetRooms()) do
        local system = room:GetSystem()
        if system and system.Powered then
            self:AddRow(system)
        end
    end
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if not layout.rows then layout.rows = {} end

        for i, row in ipairs(self.Rows) do
            layout.rows[i] = row.System:GetPowerNeeded()
        end
    end
elseif CLIENT then
    function GUI:UpdateLayout(layout)
        for i, row in ipairs(layout.rows) do
            if self.Rows[i] then
                self.Rows[i].Needed.Text = FormatNum(row, 1, 2) .. "kW"
                self.Rows[i].Limit.Text = FormatNum(self.Rows[i].System:GetPower(), 1, 2) .. "kW"
            end
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end
end
