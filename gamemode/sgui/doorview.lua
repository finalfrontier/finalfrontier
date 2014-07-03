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

if SERVER then
    resource.AddFile("materials/power.png")
else
    GUI._powerImage = Material("power.png", "smooth")
end

GUI.BaseName = BASE

GUI._door = nil
GUI._bounds = nil

GUI.CanClick = true

GUI.Enabled = false
GUI.NeedsPermission = true

GUI.OpenLockedColor = Color(0, 64, 0, 255)
GUI.OpenUnlockedColor = Color(0, 0, 0, 255)

GUI.ClosedLockedColor = Color(127, 64, 64, 255)
GUI.ClosedUnlockedColor = Color(64, 64, 64, 255)

function GUI:SetCurrentDoor(door)
    self._door = door
end

function GUI:GetCurrentDoor()
    return self._door
end

if SERVER then
    function GUI:OnClick(x, y, button)
        local ply = self:GetUsingPlayer()
        local door = self:GetCurrentDoor()

        if not self.Enabled or (self.NeedsPermission
            and not ply:HasDoorPermission(door)) then return false end

        if button == MOUSE2 then
            if door:IsLocked() then
                door:Unlock()
            else
                door:Lock()
            end
        else
            if door:IsClosed() then
                door:LockOpen()
            else
                door:UnlockClose()
            end
        end

        return true
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if self._door then
            layout.door = self._door:GetIndex()
        else
            layout.door = nil
        end
    end
end

if CLIENT then
    GUI._transform = nil
    GUI._poly = nil

    GUI.Color = Color(32, 32, 32, 255)

    function GUI:GetDoorColor()
        local door = self:GetCurrentDoor()
        if door:IsOpen() then
            if door:IsLocked() then
                return self.OpenLockedColor
            else
                return self.OpenUnlockedColor
            end
        else
            if door:IsLocked() then
                return self.ClosedLockedColor
            else
                return self.ClosedUnlockedColor
            end
        end
    end

    function GUI:ApplyTransform(transform)
        if self._transform == transform or not self._door then return end

        self._transform = transform
        
        self._poly = {}
        local bounds = Bounds()
        local ox = self:GetParent():GetGlobalLeft()
        local oy = self:GetParent():GetGlobalTop()
        for i, v in ipairs(self._door:GetCorners()) do
            local x, y = transform:Transform(v.x, v.y)
            self._poly[i] = { x = x, y = y }
            bounds:AddPoint(x - ox, y - oy)
        end
        self:SetBounds(bounds)
    end

    function GUI:GetAppliedTransform()
        return self._transform
    end

    function GUI:Draw()
        if self._transform then
            local last, lx, ly = nil, 0, 0
            local ply = self:GetUsingPlayer()
            self.CanClick = self.Enabled and (not self.NeedsPermission or
                (ply and ply.HasDoorPermission and ply:HasDoorPermission(self._door)))

            surface.SetDrawColor(self:GetDoorColor())
            surface.DrawPoly(self._poly)

            if self.CanClick and self:IsCursorInside() then
                surface.SetDrawColor(Color(255, 255, 255, 16))
                surface.DrawPoly(self._poly)
            end
        
            surface.SetDrawColor(Color(255, 255, 255, 255))
            last = self._poly[#self._poly]
            lx, ly = last.x, last.y
            for _, v in ipairs(self._poly) do
                surface.DrawLine(lx, ly, v.x, v.y)
                lx, ly = v.x, v.y
            end
            if self.Enabled and not self.CanClick then
                surface.SetDrawColor(Color(255, 255, 255, 32))
                surface.DrawLine(self._poly[1].x, self._poly[1].y,
                    self._poly[3].x, self._poly[3].y)
                surface.DrawLine(self._poly[2].x, self._poly[2].y,
                    self._poly[4].x, self._poly[4].y)
            end

            if self:GetCurrentDoor():IsUnlocked() and
                not self:GetCurrentDoor():IsPowered() and Pulse(1) >= 0.5 then
                local size = math.min(self:GetWidth(), self:GetHeight())
                local x, y = self:GetGlobalOrigin()
                x = x + (self:GetWidth() - size) * 0.5
                y = y + (self:GetHeight() - size) * 0.5
                surface.SetMaterial(self._powerImage)
                surface.SetDrawColor(Color(255, 219, 89, 255))
                surface.DrawTexturedRect(x, y, size, size)
                draw.NoTexture()
            end
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if layout.door then
            if not self._door or self._door:GetIndex() ~= layout.door then
                self:SetCurrentDoor(self:GetScreen():GetShip():GetDoorByIndex(layout.door))
            end
        else
            self._door = nil
        end
    end
end
