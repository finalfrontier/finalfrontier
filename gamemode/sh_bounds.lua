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

if SERVER then AddCSLuaFile("sh_bounds.lua") end

local _mt = {}
_mt.__index = _mt

_mt.l = 0
_mt.t = 0
_mt.r = 0
_mt.b = 0
_mt._set = false

function _mt:GetSize()
    return self.r - self.l, self.b - self.t
end

function _mt:GetCentre()
    return (self.r + self.l) / 2, (self.b + self.t) / 2
end

function _mt:GetRect()
    return self.l, self.t, self.r - self.l, self.b - self.t
end

function _mt:AddPoint(x, y)
    if not self._set then
        self.l, self.t, self.r, self.b = x, y, x, y
        self._set = true
    else
        if x < self.l then self.l = x end
        if y < self.t then self.t = y end
        if x > self.r then self.r = x end
        if y > self.b then self.b = y end
    end
end

function _mt:AddBounds(bounds)
    if not self._set then
        self.l, self.t, self.r, self.b = bounds.l, bounds.t, bounds.r, bounds.b
        self._set = true
    else
        if bounds.l < self.l then self.l = bounds.l end
        if bounds.t < self.t then self.t = bounds.t end
        if bounds.r > self.r then self.r = bounds.r end
        if bounds.b > self.b then self.b = bounds.b end
    end
end

function _mt:Move(x, y)
    self.l = self.l + x
    self.t = self.t + y
    self.r = self.r + x
    self.b = self.b + y
end

function _mt:Equals(bounds)
    return  self.l == bounds.l and self.t == bounds.t
        and self.r == bounds.r and self.b == bounds.b
end

function _mt:IsPointInside(x, y)
    if x < self.l then return false end
    if y < self.t then return false end
    if x > self.r then return false end
    if y > self.b then return false end
    return true
end

function _mt:__tostring()
    return "{(" .. self.l .. "," .. self.t .. "),(" .. self.r .. "," .. self.b .. ")}"
end

function Bounds(x, y, width, height)
    local bounds = {}
    if x then
        bounds.l, bounds.t, bounds.r, bounds.b = x, y, x + width, y + height
        bounds._set = true
    end
    return setmetatable(bounds, _mt)
end
