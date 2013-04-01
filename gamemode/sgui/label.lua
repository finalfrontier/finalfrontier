local BASE = "base"

GUI.BaseName = BASE

GUI.CanClick = false

GUI.Text = "Hello World!"
GUI.Font = "CTextSmall"
GUI.Color = Color(191, 191, 191, 255)

GUI.AlignX = TEXT_ALIGN_LEFT
GUI.AlignY = TEXT_ALIGN_TOP

if CLIENT then
    function GUI:Draw()
        surface.SetTextColor(self.Color)
        surface.SetFont(self.Font)

        local w, h = surface.GetTextSize(self.Text)
        local x, y = self:GetGlobalOrigin()

        if self.AlignX == TEXT_ALIGN_CENTER then
            x = x + (self:GetWidth() - w) / 2
        elseif self.AlignX == TEXT_ALIGN_RIGHT then
            x = x + self:GetWidth() - w
        end

        if self.AlignY == TEXT_ALIGN_CENTER then
            y = y + (self:GetHeight() - h) / 2
        elseif self.AlignY == TEXT_ALIGH_BOTTOM then
            y = y + self:GetHeight() - h
        end

        surface.SetTextPos(x, y)
        surface.DrawText(self.Text)

        self.Super[BASE].Draw(self)
    end
end
