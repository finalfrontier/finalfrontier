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
GUI.CanClick = true

GUI._scale = 256
if CLIENT then
    GUI._curScale = 256
    GUI._curX = 0
    GUI._curY = 0
end

GUI._centreObj = nil

function GUI:SetCentreObject(obj)
    obj = obj or self:GetShip():GetObject()
    if not self._centreObj then
        self._curX, self._curY = obj:GetCoordinates()
    end
    self._centreObj = obj
end

function GUI:GetCentreObject()
    if not IsValid(self._centreObj) or not self:GetShip():IsObjectInRange(self._centreObj) then
        self._centreObj = self:GetShip():GetObject()
    end

    return self._centreObj
end

function GUI:GetCentreCoordinates()
    if SERVER then
        return self:GetCentreObject():GetCoordinates()
    else
        return self._curX, self._curY
    end
end

function GUI:GetMinScale()
    local rangeSize = 8
    return math.min((self:GetWidth() - 16) / rangeSize, (self:GetHeight() - 16) / rangeSize)
end

function GUI:GetMinSensorScale()
    local sensors = self:GetShip():GetSystem("sensors")
    local rangeSize = 0.1

    if sensors then
        rangeSize = sensors:GetBaseScanRange() * 2
    end

    return math.min((self:GetWidth() - 16) / rangeSize, (self:GetHeight() - 16) / rangeSize)
end

function GUI:GetMaxScale()
    return math.min((self:GetWidth() - 16) / 0.5, (self:GetHeight() - 16) / 0.5)
end

function GUI:SetScale(scale)
    self._scale = scale

    if SERVER then
        local sys = self:GetSystem()
        if sys then sys:SetNWValue("gridscale", scale) end
    end
end

function GUI:SetInitialScale(scale)
    local sys = self:GetSystem()

    if sys then
        self:SetScale(sys:GetNWValue("gridscale", scale))
    else
        self:SetScale(scale)
    end
end

function GUI:GetScale()
    if SERVER then
        return self._scale
    else
        return self._curScale
    end
end

function GUI:GetScaleRatio()
    local max = self:GetMaxScale()
    local min = self:GetMinScale()
    return math.sqrt((self:GetScale() - min) / (max - min))
end

function GUI:SetScaleRatio(value)
    local max = self:GetMaxScale()
    local min = self:GetMinScale()
    self:SetScale(min + math.pow(math.Clamp(value, 0, 1), 2) * (max - min))
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

    function GUI:DrawArrow(sx, sy, tx, ty, size)
        local nx, ny = tx - sx, ty - sy
        local len = math.sqrt(nx * nx + ny * ny)

        if len == 0 then return end

        nx = nx / len
        ny = ny / len

        local rx, ry = -ny, nx

        nx, ny = nx * size * 2, ny * size * 2
        rx, ry = rx * size, ry * size

        surface.DrawLine(sx, sy, tx, ty)

        surface.DrawLine(tx + nx, ty + ny, tx + rx, ty + ry)
        surface.DrawLine(tx + rx, ty + ry, tx - rx, ty - ry)
        surface.DrawLine(tx - rx, ty - ry, tx + nx, ty + ny)
    end

    function GUI:Draw()
        local x, y = self:GetCentreObject():GetCoordinates()

        -- Easing
        self._curScale = self._curScale + (self._scale - self._curScale) * 0.1

        local dx, dy = universe:GetDifference(self._curX, self._curY, x, y)

        self._curX = self._curX + dx * 0.1
        self._curY = self._curY + dy * 0.1

        self._curX, self._curY = universe:WrapCoordinates(self._curX, self._curY)

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
        local px, py = ship:GetCoordinates()
        local sx, sy = self:CoordinateToScreen(px, py)
        local sensor = ship:GetSystem("sensors")

        local sensor = ship:GetSystem("sensors")
        if sensor then
            surface.SetDrawColor(Color(255, 255, 255, 2))
            surface.DrawCircle(sx + ox, sy + oy, sensor:GetBaseScanRange() * self._curScale)
        
            if sensor:IsScanning() then
                local fade = 1.25 - math.max(0, sensor:GetScanProgress() - 1)

                surface.SetDrawColor(Color(128 * fade, 128 * fade, 128 * fade, 2))
                surface.DrawCircle(sx + ox, sy + oy, sensor:GetRange() * self._curScale)
            end
        end

        local piloting = ship:GetSystem("piloting")
        if piloting and piloting:IsAccelerating() then
            surface.SetDrawColor(Color(51, 172, 45, 127))
            if piloting:IsFullStopping() then
                local size = Pulse(1) * 4 + 16
                surface.DrawOutlinedRect(sx + ox - size, sy + oy - size, size * 2, size * 2)
            else
                local tx, ty = self:CoordinateToScreen(piloting:GetTargetCoordinates())
                local size = Pulse(1) * 2 + 4

                self:DrawArrow(sx + ox, sy + oy, tx + ox, ty + oy, size)
            end
        end

        local vx, vy = self:GetShip():GetVel()
        
        vx = vx * 8 + px
        vy = vy * 8 + py

        vx, vy = self:CoordinateToScreen(vx, vy)

        surface.SetDrawColor(Color(255, 255, 255, 16))
        self:DrawArrow(sx + ox, sy + oy, vx + ox, vy + oy, 5)
        
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
                if ot == objtype.SHIP or ot == objtype.MISSILE then
                    if ot == objtype.SHIP then
                        surface.SetMaterial(SHIP_ICON)
                        if obj == ship:GetObject() then
                            surface.SetDrawColor(Color(51, 172, 45, 255))
                        else 
                            surface.SetDrawColor(Color(172, 45, 51, 191))
                        end
                    elseif ot == objtype.MISSILE then
                        surface.SetMaterial(MISSILE_ICON)
                        surface.SetDrawColor(Color(172, 45, 51, 191))
                    end
                    surface.DrawTexturedRectRotated(sx + ox, sy + oy,
                        16 * scale, 16 * scale, -obj:GetRotation())
                    draw.NoTexture()
                else
                    surface.SetDrawColor(Color(172, 45, 51, 127))
                    if ot == objtype.MODULE then
                        surface.DrawRect(sx + ox - 4 * scale, sy + oy - 4 * scale,
                            8 * scale, 8 * scale)
                    else
                        surface.DrawCircle(sx + ox, sy + oy, 8 * scale)
                    end
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
