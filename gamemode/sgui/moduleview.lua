local BASE = "base"

GUI.BaseName = BASE

GUI._slot = -1

function GUI:SetSlot(type)
    self._slot = type
end

function GUI:GetSlot()
    return self._slot
end

function GUI:GetModule()
    return self:GetRoom():GetModule(self._slot)
end

function GUI:GetGrid()
    local mdl = self:GetModule()
    if not mdl then return nil end
    return mdl:GetGrid()
end

if CLIENT then
    function GUI:IsGridLoaded()
        local mdl = self:GetModule()
        if not mdl then return false end
        return mdl:IsGridLoaded()
    end

    function GUI:Draw()
        local xs, ys = self:GetSize()
        xs, ys = xs / 40, ys / 40

        local cx, cy = self:GetGlobalCentre()
            
        if self:IsGridLoaded() then
            local mdl = self:GetModule()
            local grid = self:GetGrid()

            for i = 1, 4 do
                local x = (i - 2.5) * 10
                for j = 1, 4 do
                    local y = (j - 2.5) * 10
                    local val = grid[i][j]
                    if val == 0 then
                        surface.SetDrawColor(Color(51, 172, 45, 255))
                    elseif val == 1 then
                        surface.SetDrawColor(Color(45, 51, 172, 255))
                    else
                        surface.SetDrawColor(Color(172, 45, 51, Pulse(1) * 63 + 32))
                    end
                    surface.DrawRect(cx + (x - 4) * xs, cy + (y - 4) * ys, 8 * xs, 8 * ys)
                end
            end

            surface.SetDrawColor(Color(255, 255, 255, 16))
            surface.SetMaterial(modulematerials[mdl:GetModuleType() + 1])
            surface.DrawTexturedRect(cx - 20 * xs, cy - 20 * ys, 40 * xs, 40 * ys)
        else
            surface.SetDrawColor(Color(255, 255, 255, 4))
            surface.DrawOutlinedRect(cx - 20 * xs, cy - 20 * ys, 40 * xs, 40 * ys)

            surface.SetDrawColor(Color(255, 255, 255, 16))
            surface.DrawOutlinedRect(cx - 20 * xs, cy - 20 * ys, 40 * xs, 40 * ys)
        end
        
        self.Super[BASE].Draw(self)
    end
end
