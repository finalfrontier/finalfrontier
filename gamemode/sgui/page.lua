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

function GUI:Initialize()
    self.Super[BASE].Initialize(self)

    self:SetWidth(self:GetScreen():GetWidth())
    self:SetHeight(self:GetScreen():GetHeight())
end

function GUI:Enter()
    sgui.Log(self, "Enter")
end

function GUI:Leave()
    sgui.Log(self, "Leave")
    self:RemoveAllChildren()
end

function GUI:IsCurrentPage()
    local parent = self:GetParent()
    return parent and parent:GetCurrentPage() == self
end
