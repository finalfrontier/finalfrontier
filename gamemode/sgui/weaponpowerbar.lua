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
            if mdl:GetCharge() > 0 then
                local totbars = math.ceil(mdl:GetMaxCharge())
                local barspacing = 2
                local width = self:GetWidth()
                local barsize = (width - 8 + barspacing) / totbars

                local bars = (mdl:GetCharge() / mdl:GetMaxCharge()) * totbars

                if not mdl:CanShoot() then
                    surface.SetDrawColor(Color(191, 191, 191, 255))
                end

                for i = 0, bars - 1 do
                    if mdl:CanShoot() then
                        surface.SetDrawColor(LerpColour(Color(255, 255, 255, 255), Color(255, 255, 159, 255), Pulse(0.5, -i / totbars / 4)))
                    end

                    surface.DrawRect(self:GetGlobalLeft() + 4 + i * barsize,
                        self:GetGlobalTop() + 4, barsize - barspacing, self:GetHeight() - 8)
                end
            end
        end

        self.Super[BASE].Draw(self)
    end
end
