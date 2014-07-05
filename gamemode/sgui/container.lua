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

GUI._children = nil

function GUI:Initialize()
    self.Super[BASE].Initialize(self)

    self._children = {}
end

function GUI:UpdateGlobalBounds()
    self.Super[BASE].UpdateGlobalBounds(self)

    for _, child in pairs(self:GetChildren()) do
        child:UpdateGlobalBounds()
    end
end

function GUI:AddChild(child)
    if child:HasParent() then
        local parent = child:GetParent()
        if parent == self then return end

        parent:RemoveChild(child)
    end

    table.insert(self._children, child)
    child._parent = self

    if SERVER and self._id > 0 then
        child:AllocateNewID()
    end

    if child:GetBounds() then
        child:UpdateGlobalBounds()
    end
end

function GUI:RemoveChild(child)
    if table.HasValue(self._children, child) then
        table.RemoveByValue(self._children, child)
        child._parent = nil

        if SERVER then
            child:InvalidateID()
        end
    end
end

function GUI:RemoveAllChildren()
    while #self._children > 0 do
        self:RemoveChild(self._children[#self._children])
    end
end

function GUI:GetChild(id)
    for _, child in pairs(self:GetChildren()) do
        if child:GetID() == id then return child end
    end
    return nil
end

function GUI:GetChildren()
    return self._children
end

function GUI:Think()
    self.Super[BASE].Think(self)

    for _, child in pairs(self:GetChildren()) do
        child:Think()
    end
end

if CLIENT then
    function IsPointInside(x, y)
        local ox, oy = self:GetLeft(), self:GetTop()
        for _, child in pairs(self:GetChildren()) do
            if child:IsPointInside(x - ox, y - oy) then
                return true
            end
        end

        return false
    end

    function GUI:Click(x, y, button)
        local ox, oy = self:GetLeft(), self:GetTop()
        for _, child in pairs(self:GetChildren()) do
            if child:Click(x - ox, y - oy, button) then
                return
            end
        end

        self.Super[BASE].Click(self, x, y, button)
    end

    function GUI:Draw()
        for _, child in pairs(self:GetChildren()) do
            child:Draw()
        end
        
        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        for i, child in ipairs(self:GetChildren()) do
            if layout[i] then
                child:UpdateLayout(layout[i])
            end
        end
    end
end

if SERVER then
    GUI._lastChildCount = 0

    function GUI:AllocateNewID()
        self.Super[BASE].AllocateNewID(self)

        if not self._children then return end

        for _, child in ipairs(self._children) do
            child:AllocateNewID()
        end
    end
    
    function GUI:InvalidateID()
        self.Super[BASE].InvalidateID(self)

        if not self._children then return end

        for _, child in ipairs(self._children) do
            child:InvalidateID()
        end
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        for i, child in ipairs(self:GetChildren()) do
            if not layout[i] or layout[i].id ~= child:GetID() then
                layout[i] = {}
            end
            
            child:UpdateLayout(layout[i])
        end

        local childCount = #self:GetChildren()
        if self._lastChildCount > childCount then
            for i = childCount + 1, self._lastChildCount do
                layout[i] = nil
            end
        end

        self._lastChildCount = childCount
    end
end
