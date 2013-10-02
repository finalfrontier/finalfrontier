local BASE = "base"

GUI.BaseName = BASE

GUI._scale = 256
if CLIENT then
    GUI._curScale = 256
    GUI._curX = 0
    GUI._curY = 0
end

GUI._centreObj = nil

GUI.CanClick = true

function GUI:SetCentreObject(obj)
    obj = obj or self:GetShip():GetObject()
    if not self._centreObj then
        self._curX, self._curY = obj:GetCoordinates()
    end
    self._centreObj = obj
end

function GUI:GetCentreObject()
    return self._centreObj
end

function GUI:GetCentreCoordinates()
    if SERVER then
        return self._centreObj:GetCoordinates()
    else
        return self._curX, self._curY
    end
end

function GUI:GetMinScale()
    local rangeSize = 8
    return math.min((self:GetWidth() - 16) / rangeSize, (self:GetHeight() - 16) / rangeSize)
end

function GUI:GetMinSensorScale()
    local rangeSize = math.max(self:GetShip():GetRange() * 2, 0.1)
    return math.min((self:GetWidth() - 16) / rangeSize, (self:GetHeight() - 16) / rangeSize)
end

function GUI:GetMaxScale()
    return math.min((self:GetWidth() - 16) / 0.5, (self:GetHeight() - 16) / 0.5)
end

function GUI:SetScale(scale)
    self._scale = scale
end

function GUI:GetScale()
    if SERVER then
        return self._scale
    else
        return self._curScale
    end
end

function GUI:CoordinateToScreen(x, y)
    local cx, cy = self:GetCentreCoordinates()
    x, y = universe:GetDifference(cx, cy, x, y)

    x = x * self:GetScale() + self:GetWidth() * 0.5
    y = y * self:GetScale() + self:GetHeight() * 0.5

    return x, y
end

function GUI:ScreenToCoordinate(x, y)
    local cx, cy = self:GetCentreCoordinates()
    return universe:WrapCoordinates((x - self:GetWidth() * 0.5) / self:GetScale() + cx,
        (y - self:GetHeight() * 0.5) / self:GetScale() + cy)
end

function GUI:GetNearestObject(x, y)
    local ship = self:GetShip()
    local objects = ents.FindByClass("info_ff_object")
    local closest = nil
    local bestdist = 0
    for _, obj in pairs(objects) do
        if ship:IsObjectInRange(obj) then
            local sx, sy = self:CoordinateToScreen(obj:GetCoordinates())

            local dist = math.pow(sx - x, 2) + math.pow(sy - y, 2)
            if dist < 32 * 32 and (dist < bestdist or not closest) then
                closest = obj
                bestdist = dist
            end
        end
    end

    return closest
end

if SERVER then
    function GUI:OnSelectObject(obj, button)
        self:SetCentreObject(obj)
        self:GetScreen():UpdateLayout()
        return true
    end

    function GUI:OnClickSelectedObject(obj, button)
        return false
    end
    
    function GUI:OnClick(x, y, button)
        x = x - self:GetLeft()
        y = y - self:GetTop()
        local nearest = self:GetNearestObject(x, y)
        if nearest ~= self:GetCentreObject() then
            return self:OnSelectObject(nearest, button)
        elseif nearest ~= nil then
            return self:OnClickSelectedObject(nearest, button)
        end
        return false
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.scale = self:GetScale()
        layout.centre = self:GetCentreObject()
    end
elseif CLIENT then
    function GUI:UpdateLayout(layout)
        self:SetScale(layout.scale)
        self:SetCentreObject(layout.centre)

        self.Super[BASE].UpdateLayout(self, layout)
    end

    function GUI:Draw()
        local x, y = self:GetCentreObject():GetCoordinates()

        -- Easing
        self._curScale = self._curScale + (self._scale - self._curScale) * 0.1
        self._curX = self._curX + (x - self._curX) * 0.1
        self._curY = self._curY + (y - self._curY) * 0.1

        x, y = self:GetCentreCoordinates()
        local ox, oy = self:GetGlobalOrigin()
        local l = x - self:GetWidth() * 0.5 / self._curScale
        local t = y - self:GetHeight() * 0.5 / self._curScale
        local r = l + self:GetWidth() / self._curScale
        local b = t + self:GetHeight() / self._curScale

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
        surface.SetDrawColor(Color(255, 255, 255, 2))
        surface.DrawCircle(sx + ox, sy + oy, ship:GetRange() * self._curScale)

        local sensor = ship:GetSystem("sensors")
        if sensor and sensor:IsScanning() then
            surface.SetDrawColor(Color(128, 128, 128, 2))
            surface.DrawCircle(sx + ox, sy + oy, sensor:GetActiveScanDistance() * self._curScale)
        end    

        local piloting = ship:GetSystem("piloting")
        if piloting then
            local tx, ty = self:CoordinateToScreen(piloting:GetTargetCoordinates())

            if math.abs(tx - sx) > 0.5 or math.abs(ty - sy) > 0.5 then
                surface.SetDrawColor(Color(51, 172, 45, 127))
                surface.DrawOutlinedRect(tx + ox - 8, ty + oy - 8, 16, 16)

                surface.SetDrawColor(Color(51, 172, 45, 32))
                surface.DrawLine(sx + ox, sy + oy, tx + ox, ty + oy)
            end
        end
        
        local closest = self:GetNearestObject(self:GetLocalCursorPos())
        local objects = ents.FindByClass("info_ff_object")
        for _, obj in pairs(objects) do
            if ship:IsObjectInRange(obj) then
                sx, sy = self:CoordinateToScreen(obj:GetCoordinates())
                local scale = 1
                if obj == closest then
                    scale = 1 + Pulse(1)
                    surface.SetDrawColor(Color(255, 255, 255, 4))
                    surface.DrawCircle(sx + ox, sy + oy, 16)
                end

                local ot = obj:GetObjectType()
                if ot == objtype.ship or ot == objtype.missile then
                    if ot == objtype.ship then
                        surface.SetMaterial(SHIP_ICON)
                        if obj == ship:GetObject() then
                            surface.SetDrawColor(Color(51, 172, 45, 255))
                        else 
                            surface.SetDrawColor(Color(172, 45, 51, 191))
                        end
                    elseif ot == objtype.missile then
                        surface.SetMaterial(MISSILE_ICON)
                        surface.SetDrawColor(Color(172, 45, 51, 191))
                    end
                    surface.DrawTexturedRectRotated(sx + ox, sy + oy,
                        16 * scale, 16 * scale, -obj:GetRotation())
                    draw.NoTexture()
                else
                    surface.SetDrawColor(Color(172, 45, 51, 127))
                    surface.DrawCircle(sx + ox, sy + oy, 8 * scale)
                end
            end
        end

        surface.SetDrawColor(Color(255, 255, 255, 2))
        for i = math.ceil(l), math.floor(r) do
            local j = (i - x) * self._curScale + self:GetWidth() * 0.5
            surface.DrawLine(ox + j, oy, ox + j, oy + self:GetHeight())
        end
        for i = math.ceil(t), math.floor(b) do
            local j = (i - y) * self._curScale + self:GetHeight() * 0.5
            surface.DrawLine(ox, oy + j, ox + self:GetWidth(), oy + j)
        end
        surface.SetDrawColor(Color(255, 255, 255, 127))
        surface.DrawOutlinedRect(self:GetGlobalRect())

        render.SetStencilEnable(false)

        self.Super[BASE].Draw(self)
    end
end
