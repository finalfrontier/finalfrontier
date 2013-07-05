local BASE = "base"

GUI.BaseName = BASE

function GUI:GetWeaponModule()
    return self:GetParent():GetWeaponModule()
end

function GUI:GetWeapon()
    return self:GetParent():GetWeapon()
end

if CLIENT then
    function GUI:Draw()
        if self:GetWeapon() then
            surface.SetDrawColor(Color(63, 63, 63, 255))
            surface.DrawOutlinedRect(self:GetGlobalRect())

            local mdl = self:GetWeaponModule()
            if mdl:GetCharge() == 0 then
                surface.SetTextColor(Color(172, 45, 51, 255))
                surface.SetFont("CTextSmall")

                text = "NO CHARGE"

                local w, h = surface.GetTextSize(text)
                local x = self:GetGlobalLeft() + (self:GetWidth() - w) / 2
                local y = self:GetGlobalTop() + (self:GetHeight() - h) / 2

                surface.SetTextPos(x, y)
                surface.DrawText(text)
            end
        end

        self.Super[BASE].Draw(self)
    end
end
