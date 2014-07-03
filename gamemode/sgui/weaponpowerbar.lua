-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

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
