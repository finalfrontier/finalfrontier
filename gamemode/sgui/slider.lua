local BASE = "base"

GUI.BaseName = BASE

GUI.CanClick = true

GUI.Margin = 4

GUI.Value = 0
GUI.Snap = 0.05

GUI.Color = Color(191, 191, 191, 255)
GUI.DisabledColor = Color(64, 64, 64, 255)
GUI.HighlightColorNeg = Color(0, 0, 0, 127)
GUI.HighlightColorPos = Color(191, 191, 191, 32)
GUI.TextColorNeg = Color(0, 0, 0, 255)
GUI.TextColorPos = GUI.Color

if SERVER then
    function GUI:OnClick(x, y, button)
        local oldValue = self.Value
        self.Value = math.Clamp((x - self:GetLeft() - self.Margin) /
            (self:GetWidth() - self.Margin * 2), 0, 1)
        
        if self.Snap > 0 then
            self.Value = math.Round(self.Value / self.Snap) * self.Snap
        end

        if self.Value ~= oldValue then
            self:OnValueChanged(self.Value)
            self.Screen:UpdateLayout()
        end
    end

    function GUI:OnValueChanged(value)
        return
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.value = self.Value
    end
elseif CLIENT then
    function GUI:GetValueText(value)
        return tostring(math.Round(value * 100)) .. "%"
    end

    function GUI:DrawValueText(text)
        surface.SetFont("CTextSmall")
        local x, y, w, h = self:GetGlobalRect()
        local a = x + self.Margin + (w - self.Margin * 2) * self.Value
        local wid, hei = surface.GetTextSize(text)
        if wid < a - x - self.Margin * 2 then
            surface.SetTextColor(self.TextColorNeg)
            surface.SetTextPos(a - self.Margin - wid, y + (h - hei) / 2)
        elseif wid < self:GetGlobalRight() - a - self.Margin * 2 then
            surface.SetTextColor(self.TextColorPos)
            surface.SetTextPos(a + self.Margin, y + (h - hei) / 2)
        end
        surface.DrawText(text)
    end

    function GUI:Draw()
        if self.CanClick then
            surface.SetDrawColor(self.Color)
        else
            surface.SetDrawColor(self.DisabledColor)
        end
        local x, y, w, h = self:GetGlobalRect()
        surface.DrawOutlinedRect(x, y, w, h)
        surface.DrawRect(x + self.Margin, y + self.Margin,
            (w - self.Margin * 2) * self.Value, h - self.Margin * 2)

        local a = x + self.Margin + (w - self.Margin * 2) * self.Value

        if self.CanClick and self:IsCursorInside() then
            local cx = self:GetCursorPos() - self:GetLeft()
            local value = math.Clamp((cx - self.Margin) /
                (self:GetWidth() - self.Margin * 2), 0, 1)
            if self.Snap > 0 then
                value = math.Round(value / self.Snap) * self.Snap
            end
            
            local b = x + self.Margin + (w - self.Margin * 2) * value

            if b >= a then
                surface.SetDrawColor(self.HighlightColorPos)
                surface.DrawRect(a, y + self.Margin, b - a,
                    h - self.Margin * 2)
            else
                surface.SetDrawColor(self.HighlightColorNeg)
                surface.DrawRect(b, y + self.Margin, a - b,
                    h - self.Margin * 2)
            end
        end

        self:DrawValueText(self:GetValueText(self.Value))

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Value = layout.value

        self.Super[BASE].UpdateLayout(self, layout)
    end
end
