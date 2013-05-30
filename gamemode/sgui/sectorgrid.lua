local BASE = "base"

GUI.BaseName = BASE

GUI._scale = 32

GUI._centreX = 0
GUI._centreY = 0

function GUI:SetCentreCoordinates(x, y)
    self._centreX = x
    self._centreY = y
end

function GUI:GetCentreCoordinates()
    return self._centreX, self._centreY
end

function GUI:SetScale(scale)
    self._scale = scale
end

function GUI:GetScale()
    return self._scale
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.scale = self:GetScale()
    end
elseif CLIENT then
    function GUI:UpdateLayout(layout)
        self:SetScale(layout.scale)

        self.Super[BASE].UpdateLayout(self, layout)
    end

    function GUI:CoordinateToScreen(x, y)
        local cx, cy = self:GetCentreCoordinates()
        return (x - cx) * self:GetScale() + self:GetWidth() * 0.5,
            (y - cy) * self:GetScale() + self:GetHeight() * 0.5
    end

    function GUI:ScreenToCoordinate(x, y)
        local cx, cy = self:GetCentreCoordinates()
        return (x - self:GetWidth() * 0.5) / self:GetScale() + cx,
            (y - self:GetHeight() * 0.5) / self:GetScale() + cy
    end

    function GUI:Draw()
        local x, y = self:GetCentreCoordinates()
        local ox, oy = self:GetGlobalOrigin()
        local l = x - self:GetWidth() * 0.5 / self:GetScale()
        local t = y - self:GetHeight() * 0.5 / self:GetScale()
        local r = l + self:GetWidth() / self:GetScale()
        local b = t + self:GetHeight() / self:GetScale()

        local ship = self:GetShip()
        surface.SetMaterial(SHIP_ICON)
        surface.SetDrawColor(Color(51, 172, 45, 255))
        local sx, sy = self:CoordinateToScreen(ship:GetCoordinates())
        surface.DrawTexturedRectRotated(sx + ox, sy + oy, 32, 32, ship:GetRotation())

        surface.SetDrawColor(Color(255, 255, 255, 8))
        for i = math.ceil(l), math.floor(r) do
            local j = (i - x) * self:GetScale() + self:GetWidth() * 0.5
            surface.DrawLine(ox + j, oy, ox + j, oy + self:GetHeight())
        end
        for i = math.ceil(t), math.floor(b) do
            local j = (i - y) * self:GetScale() + self:GetHeight() * 0.5
            surface.DrawLine(ox, oy + j, ox + self:GetWidth(), oy + j)
        end
        surface.SetDrawColor(Color(255, 255, 255, 127))
        surface.DrawOutlinedRect(self:GetGlobalRect())

        self.Super[BASE].Draw(self)
    end
end
