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

local BASE = "page"

GUI.BaseName = BASE

GUI.PermNoneColor = Color(127, 127, 127, 255)
GUI.PermAccessColor = Color(45, 51, 172, 255)
GUI.PermSystemColor = Color(51, 172, 45, 255)
GUI.PermSecurityColor = Color(172, 45, 51, 255)

GUI._playerList = nil
GUI._buttons = nil

function GUI:UpdateButtons()
    if self._buttons then
        for _, btn in pairs(self._buttons) do
            btn:Remove()
        end
        self._buttons = nil
    end

    if self._playerList then
        self._buttons = {}
        for i, ply in ipairs(self._playerList) do
            if i > 12 then break end
            local btn = sgui.Create(self, "securitybutton")
            btn:SetPlayer(ply)
            btn:SetSize((self:GetWidth() - 16) / 2 - 4, 48)
            btn:SetCentre(self:GetWidth() / 4
                + math.floor((i - 1) / 6) * self:GetWidth() / 2,
                ((i - 1) % 6) * 48 + 32)
            table.insert(self._buttons, btn)
        end
    end
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    local function keyLabel(index, text, clr)
        local lbl = sgui.Create(self, "label")
        lbl.Text = text
        lbl:SetSize((self:GetWidth() - 32) / 5 + 16, 64)
        lbl:SetCentre((self:GetWidth() - 32) * (2 * index + 1) / 10 + 16, self:GetHeight() - 32)
        lbl.AlignX = TEXT_ALIGN_CENTER
        lbl.AlignY = TEXT_ALIGN_CENTER
        lbl.Color = clr or lbl.Color
    end

    keyLabel(0, "COLOR KEY:", Color(64, 64, 64, 255))
    keyLabel(1, "NONE", self.PermNoneColor)
    keyLabel(2, "ACCESS", self.PermAccessColor)
    keyLabel(3, "SYSTEM", self.PermSystemColor)
    keyLabel(4, "SECURITY", self.PermSecurityColor)

    if SERVER then
        self._playerList = self:GetShip():GetPlayers()
        table.sort(self._playerList, function(a, b)
            return self:GetScreen():GetPos():DistToSqr(a:GetPos())
                < self:GetScreen():GetPos():DistToSqr(b:GetPos())
        end)
        
        self:UpdateButtons()
    end
end

function GUI:Leave()
    self.Super[BASE].Leave(self)

    self._playerList = nil
    self._buttons = nil
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if not self._playerList then
            layout.players = nil
        else
            if not layout.players or #layout.players > #self._playerList then
                layout.players = {}
            end

            for i, ply in ipairs(self._playerList) do
                layout.players[i] = ply
            end
        end
    end    
end

if CLIENT then
    function GUI:UpdateLayout(layout)
        if layout.players then
            if not self._playerList or #self._playerList > #layout.players then
                self._playerList = {}
            end

            local changed = false
            for i, ply in pairs(layout.players) do
                if not self._playerList[i] or self._playerList[i] ~= ply then
                    changed = true
                    self._playerList[i] = ply
                end
            end

            if changed then self:UpdateButtons() end
        else
            if self._playerList then
                self._playerList = nil
                self:UpdateButtons()
            end
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end    
end
