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

local BASE = "container"

GUI.BaseName = BASE

GUI._player = nil

GUI._permButton = nil
GUI._adrmButton = nil

function GUI:Initialize()
    self.Super[BASE].Initialize(self)

    self._permButton = sgui.Create(self, "button")
    self._adrmButton = sgui.Create(self, "button")

    if SERVER then
        self._permButton.OnClick = function(btn)
            local ply = self:GetPlayer()
            local room = self:GetRoom()
            if not IsValid(ply) then return false end
            local perm = ply:GetPermission(room)
            perm = perm + 1
            if perm > permission.SECURITY then perm = permission.ACCESS end
            ply:SetPermission(self:GetRoom(), perm)
            return true
        end

        self._adrmButton.OnClick = function(btn)
            local ply = self:GetPlayer()
            local room = self:GetRoom()
            if not IsValid(ply) then return false end

            if ply:GetPermission(room) <= permission.NONE then
                ply:SetPermission(self:GetRoom(), permission.ACCESS)
            else
                ply:SetPermission(self:GetRoom(), permission.NONE)
            end
            return true
        end
    end

    self._adrmButton.Text = "X"
end

function GUI:SetBounds(bounds)
    self.Super[BASE].SetBounds(self, bounds)

    self._permButton:SetWidth(self:GetWidth() - self:GetHeight())
    self._adrmButton:SetWidth(self:GetHeight())
    self._permButton:SetHeight(self:GetHeight())
    self._adrmButton:SetHeight(self:GetHeight())

    self._adrmButton:SetOrigin(self._permButton:GetRight(), 0)
end

function GUI:GetPlayer()
    return self._player
end

function GUI:SetPlayer(ply)
    if not IsValid(ply) then
        self._player = nil
        self._permButton.Text = "[disconnected]"
    else
        self._player = ply
        self._permButton.Text = ply:Nick()
    end
end

if CLIENT then
    function GUI:Draw()
        if IsValid(self._player) then
            self._adrmButton.Text = "-"
            self._permButton.CanClick = true
            self._adrmButton.CanClick = true
            local perm = self._player:GetPermission(self:GetRoom())
            if perm >= permission.SECURITY then
                self._permButton.Color = self:GetParent().PermSecurityColor
            elseif perm >= permission.SYSTEM then
                self._permButton.Color = self:GetParent().PermSystemColor
            elseif perm >= permission.ACCESS then
                self._permButton.Color = self:GetParent().PermAccessColor
            else
                self._permButton.Color = self:GetParent().PermNoneColor
                self._adrmButton.Text = "+"
                self._permButton.CanClick = false
            end
        else
            self._permButton.Color = self:GetParent().PermNoneColor
            self._adrmButton.Text = "+"
            self._permButton.CanClick = false
            self._adrmButton.CanClick = false
        end

        self.Super[BASE].Draw(self)
    end
end