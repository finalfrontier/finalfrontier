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

if SERVER then AddCSLuaFile("sh_matrix.lua") end

local _mt = {}
_mt.__index = _mt

_mt.xx = 1
_mt.xy = 0
_mt.yx = 0
_mt.yy = 1

function _mt:Mul(mat)
    return Matrix2D(
        mat.xx * self.xx + mat.xy * self.yx, mat.xx * self.xy + mat.xy * self.yy,
        mat.yx * self.xx + mat.yy * self.yx, mat.yx * self.xy + mat.yy * self.yy)
end

function _mt:Rotate(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    
    return self:Mul(Matrix2D(c, -s, s, c))
end

function _mt:Transform(x, y)
    return x * self.xx + y * self.xy, x * self.yx + y * self.yy
end

function _mt:Scale(x, y)
    y = y or x
    return Matrix2D(self.xx * x, self.xy * y, self.yx * x, self.yy * y)
end

function Matrix2D(xx, xy, yx, yy)
    return setmetatable({ xx = xx or 1, xy = xy or 0, yx = yx or 0, yy = yy or 1 }, _mt)
end
