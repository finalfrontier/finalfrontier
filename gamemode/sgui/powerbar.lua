local BASE = "slider"

GUI.BaseName = BASE

GUI.CanClick = false
GUI.TextColor = Color(191, 191, 191, 255)

if CLIENT then
    function GUI:GetValueText(value)
        return FormatNum(self:GetSystem():GetPower(), 1, 2) .. "kW / " ..
            FormatNum(self:GetSystem():GetPowerNeeded(), 1, 2) .. "kW"
    end

    function GUI:DrawValueText(value)
        local text = self:GetValueText(value)
        surface.SetFont("CTextSmall")
        local x, y = self:GetGlobalCentre()
        local wid, hei = surface.GetTextSize(text)
        surface.SetTextColor(self.TextColor)
        surface.SetTextPos(x - wid / 2, y - hei / 2)
        surface.DrawText(text)
    end

    function GUI:Draw()
        if self:GetSystem():GetPowerNeeded() > 0 then
            self.Value = math.min(1, self:GetSystem():GetPower()
                / self:GetSystem():GetPowerNeeded())
        else
            self.Value = 0
        end

        self.Super[BASE].Draw(self)    
    end
end
