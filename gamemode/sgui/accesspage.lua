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

GUI._roomView = nil
GUI._doorViews = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._roomView = sgui.Create(self:GetScreen(), "roomview")
    self._roomView:SetCurrentRoom(self:GetRoom())

    self._doorViews = {}
    if self:GetRoom() then
        for _, door in ipairs(self:GetRoom():GetDoors()) do
            local doorview = sgui.Create(self, "doorview")
            doorview:SetCurrentDoor(door)
            doorview.Enabled = true
            doorview.NeedsPermission = true
            self._doorViews[door] = doorview
        end
    end

    self:AddChild(self._roomView)

    local margin = 16

    self._roomView:SetBounds(Bounds(
        margin,
        margin,
        self:GetWidth() - margin * 2,
        self:GetHeight() - margin * 2
    ))

    if CLIENT then
        for door, doorview in pairs(self._doorViews) do
            doorview:ApplyTransform(self._roomView:GetAppliedTransform())
        end
    end
end
