local BASE = "base"

GUI.BaseName = BASE

if CLIENT then
    GUI.Color = Color(255, 255, 255, 255)
    GUI.Material = WHITE

    function GUI:Draw()
        if self.Material then
            surface.SetDrawColor(self.Color)
            surface.SetMaterial(self.Material)
            surface.DrawTexturedRect(
                self:GetGlobalLeft(),
                self:GetGlobalTop(),
                self:GetWidth(),
                self:GetHeight()
            )
            draw.NoTexture()
        end
        
        self.Super[BASE].Draw(self)
    end
end
