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

GUI._shipview = nil
GUI._powerbar = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._shipview = sgui.Create(self, "shipview")
    self._shipview:SetCurrentShip(self:GetShip())

    for _, door in pairs(self._shipview:GetDoorElements()) do
        door.Enabled = true
        door.NeedsPermission = false
    end

    for _, room in pairs(self._shipview:GetRoomElements()) do
        if room:GetCurrentRoom() == self:GetRoom() then
            room.CanClick = true
            if SERVER then
                function room.OnClick(room, x, y, btn)
                    if btn == MOUSE1 then
                        self:GetSystem():ToggleAllOpen()
                    else
                        self:GetSystem():ToggleAllLocked()
                    end
                    return true
                end
            end
        elseif CLIENT then
            function room.GetRoomColor(room)
                return Color(0, 0, 0, 255)
            end
        end
    end

    local margin = 16
    local barheight = 48

    self._powerbar = sgui.Create(self, "powerbar")
    self._powerbar:SetSize(self:GetWidth() - margin * 2, barheight)
    self._powerbar:SetOrigin(margin, self:GetHeight() - margin - barheight)

    self._shipview:SetBounds(Bounds(
        margin,
        margin * 0.5,
        self:GetWidth() - margin * 2,
        self:GetHeight() - margin * 2.5 - barheight
    ))
end
