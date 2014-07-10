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

if SERVER then AddCSLuaFile("sh_transform2d.lua") end

local _mt = {}
_mt.__index = _mt

_mt.Matrix = nil
_mt.Offset = nil

function _mt:Translate(x, y)
    self.Offset.x = self.Offset.x + x
    self.Offset.y = self.Offset.y + y
end

function _mt:Scale(x, y)
    self.Matrix = self.Matrix:Scale(x, y)
end

function _mt:Rotate(ang)
    self.Matrix = self.Matrix:Rotate(ang)
end

function _mt:Transform(x, y)
    x, y = self.Matrix:Transform(x, y)
    return x + self.Offset.x, y + self.Offset.y
end

function Transform2D()
    return setmetatable({ Matrix = Matrix2D(1, 0, 0, 1), Offset = { x = 0, y = 0 } }, _mt)
end

function FindBestTransform(sourceBounds, destBounds, canRotate, flip, angle)
    local src = {}
    src.width, src.height = sourceBounds:GetSize()
    src.centrex, src.centrey = sourceBounds:GetCentre()
    local trans = Transform2D()
    
    if angle then
        angle = math.Round(angle / 90)
        trans:Rotate(angle * math.pi / 2)
        if (math.abs(angle) % 2) == 1 then
            src.width, src.height = src.height, src.width
        end
    elseif canRotate and src.width < src.height then
        trans:Rotate(math.pi / 2)
        src.width, src.height = src.height, src.width
    end
    
    if flip then trans:Scale(1, -1) end
    
    src.ratio = src.width / src.height
    
    local dest = {}
    dest.width, dest.height = destBounds:GetSize()
    dest.centrex, dest.centrey = destBounds:GetCentre()
    dest.ratio = dest.width / dest.height
    
    if dest.ratio < src.ratio then
        trans:Scale(dest.width / src.width)
    else
        trans:Scale(dest.height / src.height)
    end
    
    local sx, sy = trans:Transform(src.centrex, src.centrey)
    trans:Translate(dest.centrex - sx, dest.centrey - sy)
    return trans
end
