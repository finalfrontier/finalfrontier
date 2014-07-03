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

GUI._room = nil

function GUI:SetCurrentRoom(room)
    if self._room == room then return end

    self._room = room

    if CLIENT and self._room then
        self:FindTransform()
    end
end

function GUI:GetCurrentRoom()
    return self._room
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if self._room then
            layout.room = self._room:GetIndex()
        else
            layout.room = nil
        end
    end
elseif CLIENT then
    GUI._transform = nil

    GUI._corners = nil
    GUI._details = nil
    GUI._polys = nil

    GUI._iconBounds = nil

    GUI.Color = Color(32, 32, 32, 255)

    function GUI:SetBounds(bounds)
        self.Super[BASE].SetBounds(self, bounds)
        self:FindTransform()
    end

    function GUI:GetIconBounds()
        return self._iconBounds
    end

    function GUI:FindTransform()
        if not self._room then return end

        local roomBounds = Bounds()
        roomBounds:AddBounds(self._room:GetBounds())
        for _, door in ipairs(self._room:GetDoors()) do
            roomBounds:AddBounds(door:GetBounds())
        end
        local angle = self:GetScreen():GetAngles().Yaw + 90
        
        self:ApplyTransform(FindBestTransform(roomBounds,
            self:GetGlobalBounds(), false, true, angle), true)
    end

    function GUI:ApplyTransform(transform, updateBounds)
        if self._transform == transform or not self._room then return end

        self._transform = transform
        
        local x, y
        local newBounds = Bounds()

        self._corners = {}
        for i, v in ipairs(self._room:GetCorners()) do
            x, y = transform:Transform(v.x, v.y)
            self._corners[i] = { x = x, y = y }
            newBounds:AddPoint(x, y)
        end

        self._details = {}
        if self._room:GetDetails() then
            for i, v in ipairs(self._room:GetDetails()) do
                x, y = transform:Transform(v.a.x, v.a.y)
                self._details[i] = { a = { x = x, y = y } }
                x, y = transform:Transform(v.b.x, v.b.y)
                self._details[i].b = { x = x, y = y }
            end
        end

        self._polys = {}
        for j, p in ipairs(self._room:GetConvexPolys()) do
            self._polys[j] = {}
            for i, v in ipairs(p) do
                x, y = transform:Transform(v.x, v.y)
                self._polys[j][i] = { x = x, y = y }
            end
        end

        self._iconBounds = Bounds()
        local cx, cy = self._room:GetBounds():GetCentre()
        x, y = cx - 64, cy - 64
        self._iconBounds:AddPoint(transform:Transform(x, y))
        x, y = cx + 64, cy + 64
        self._iconBounds:AddPoint(transform:Transform(x, y))

        if updateBounds then
            newBounds:Move(self:GetLeft() - self:GetGlobalLeft(),
                self:GetTop() - self:GetGlobalTop())
            self.Super[BASE].SetBounds(self, newBounds)
        end
    end

    function GUI:GetAppliedTransform()
        return self._transform
    end

    function GUI:IsPointInside(x, y)
        local xo = self:GetLeft() - self:GetGlobalLeft()
        local yo = self:GetTop() - self:GetGlobalTop()
        return self.Super[BASE].IsPointInside(self, x, y) and self._polys
            and IsPointInsidePolyGroup(self._polys, x - xo, y - yo)
    end

    function GUI:GetRoomColor()
        return self.Color
    end
    
    function GUI:Draw()
        if self._transform then
            local last, lx, ly = nil, 0, 0

            surface.SetDrawColor(self:GetRoomColor())

            for i, poly in ipairs(self._polys) do
                surface.DrawPoly(poly)
            end
            
            if self.CanClick and self:IsCursorInside() then
                surface.SetDrawColor(Color(255, 255, 255, 16))
                for i, poly in ipairs(self._polys) do
                    surface.DrawPoly(poly)
                end
            end

            surface.SetDrawColor(Color(255, 255, 255, 32))
            for _, v in ipairs(self._details) do
                surface.DrawLine(v.a.x, v.a.y, v.b.x, v.b.y)
            end

            surface.SetDrawColor(Color(255, 255, 255, 255))
            last = self._corners[#self._corners]
            lx, ly = last.x, last.y
            for _, v in ipairs(self._corners) do
                surface.DrawLine(lx, ly, v.x, v.y)
                lx, ly = v.x, v.y
            end

            local sys = self._room:GetSystem()
            if sys then
                if sys.Icon then
                    surface.SetMaterial(sys.Icon)
                    surface.SetDrawColor(Color(255, 255, 255, 32))
                    surface.DrawTexturedRect(self._iconBounds:GetRect())
                end

                if sys.Powered and sys:GetPower() < sys:GetPowerNeeded() - 0.005
                    and Pulse(1) >= 0.5 then
                    surface.SetMaterial(POWER)
                    surface.SetDrawColor(LerpColour(Color(255, 44, 33, 255),
                        Color(255, 219, 89, 255),
                        sys:GetPower() / sys:GetPowerNeeded()))
                    surface.DrawTexturedRect(self._iconBounds:GetRect())
                end
            end

            surface.SetMaterial(PLAYER_DOT)
            for _, ply in pairs(player.GetAll()) do
                if ply:IsInRoom(self._room) then
                    if ply == LocalPlayer() then
                        surface.SetDrawColor(Color(51, 172, 45, 255))
                    else
                        surface.SetDrawColor(Color(172, 45, 51, 255))
                    end

                    local pos = ply:GetPos()
                    local l, t = self._transform:Transform(pos.x - 32, pos.y - 32)
                    local r, b = self._transform:Transform(pos.x + 32, pos.y + 32)
                    l, r = math.min(l, r), math.max(l, r)
                    t, b = math.min(t, b), math.max(t, b)
                    local ang = ply:EyeAngles().y - self:GetScreen():GetAngles().y - 90
                    surface.DrawTexturedRectRotated(
                        (l + r) * 0.5, (t + b) * 0.5, r - l, b - t, ang)
                end
            end

            draw.NoTexture()
        end
        
        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if layout.room then
            if not self._room or self._room:GetIndex() ~= layout.room then
                self:SetCurrentRoom(self:GetScreen():GetShip():GetRoomByIndex(layout.room))
            end
        else
            self._room = nil
        end
    end
end
