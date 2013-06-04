local BASE = "base"

GUI.BaseName = BASE

GUI._scale = 128

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

        x = (x - cx) * self:GetScale() + self:GetWidth() * 0.5
        y = (y - cy) * self:GetScale() + self:GetHeight() * 0.5

        local xstep = self:GetScale() * universe:GetHorizontalSectors()
        local ystep = self:GetScale() * universe:GetVerticalSectors()

        if x < self:GetWidth() - xstep then
            x = x + xstep
        elseif x >= xstep then
            x = x - xstep
        end

        if y < self:GetHeight() - ystep then
            y = y + ystep
        elseif x >= ystep then
            y = y - ystep
        end

        return x, y
    end

    function GUI:ScreenToCoordinate(x, y)
        local cx, cy = self:GetCentreCoordinates()
        return universe:WrapCoordinates((x - self:GetWidth() * 0.5) / self:GetScale() + cx,
            (y - self:GetHeight() * 0.5) / self:GetScale() + cy)
    end

    function GUI:Draw()
        local x, y = self:GetCentreCoordinates()
        local ox, oy = self:GetGlobalOrigin()
        local l = x - self:GetWidth() * 0.5 / self:GetScale()
        local t = y - self:GetHeight() * 0.5 / self:GetScale()
        local r = l + self:GetWidth() / self:GetScale()
        local b = t + self:GetHeight() / self:GetScale()

        render.ClearStencil()
        render.SetStencilEnable(true)

        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
        render.SetStencilReferenceValue(1)

        surface.SetDrawColor(Color(0, 0, 0, 255))
        surface.DrawRect(self:GetGlobalRect())

        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
     
        local ship = self:GetShip()
        local sx, sy = self:CoordinateToScreen(ship:GetCoordinates())
        surface.SetDrawColor(Color(51, 172, 45, 8))
        surface.DrawCircle(sx + ox, sy + oy, ship:GetRange() * self:GetScale())
        surface.SetMaterial(SHIP_ICON)
        surface.SetDrawColor(Color(51, 172, 45, 255))
        surface.DrawTexturedRectRotated(sx + ox, sy + oy, 16, 16, ship:GetRotation())
        draw.NoTexture()

        surface.SetDrawColor(Color(172, 45, 51, 32))
        local objects = ents.FindByClass("info_ff_object")
        for _, obj in pairs(objects) do
            if obj ~= ship:GetObject() and ship:IsObjectInRange(obj) then
                sx, sy = self:CoordinateToScreen(obj:GetCoordinates())
                surface.DrawCircle(sx + ox, sy + oy, 2)
            end
        end

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

        render.SetStencilEnable(false)

        self.Super[BASE].Draw(self)
    end
end
