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

local _mt = {}
_mt.__index = _mt

_mt._pos = Vector(0, 0, 0)
_mt._scale = 1
_mt._clr = Color(255, 255, 255, 255)

function _mt:GetPos()
    return self._pos
end

function _mt:GetScale()
    return self._scale
end

function _mt:GetColor()
    return self._clr
end

function _mt:Render(origin, vel)
    local pos = self._pos - origin

    if pos.x > 128 then
        pos.x = pos.x - 256
    elseif pos.x <= -128 then
        pos.x = pos.x + 256
    end

    if pos.y > 128 then
        pos.y = pos.y - 256
    elseif pos.y <= -128 then
        pos.y = pos.y + 256
    end

    local dist = pos:Length()
    local clr = self._clr

    if dist > 96 then
        clr.a = math.Round(math.max(0, (128 - dist) / 32) * 255)
    elseif dist < 8 then
        clr.a = math.Round(math.max(0, (dist - 4) / 4) * 255)
    end

    if clr.a <= 0 then return end

    render.DrawQuadEasy(pos, -pos:GetNormalized(), self._scale, self._scale, clr, 0)
end

function Star(pos, scale, clr)
    return setmetatable({ _pos = pos, _scale = scale, _clr = clr }, _mt)
end

local _stars = nil
local _starMat = nil

local function _GenerateStars()
    _stars = {}

    for i = 1, 256 do
        local scale = math.pow(math.random(), 2) + 2
        local shift = math.random() * 2 - 1

        local pos = Vector(
            math.random() * 256 - 128,
            math.random() * 256 - 128,
            math.random() * 128 - 64)

        local clr = Color(
            math.floor(224 + shift * 32),
            math.floor(255 - math.abs(shift) * 32),
            math.floor(224 - shift * 32),
            255)

        table.insert(_stars, Star(pos, scale, clr))
    end
end

local _pushedMat = nil
function GM:PreDrawSkyBox()
    local ship = LocalPlayer():GetShip()

    _pushedMat = nil

    if not ship then return true end

    local obj = ship:GetObject()

    if not IsValid(obj) then return true end

    local mat = Matrix()

    mat:Rotate(Angle(0, obj:GetRotation(), 0))

    cam.PushModelMatrix(mat)

    _pushedMat = mat
end

function GM:PostDraw2DSkyBox()
    if not _pushedMat then return end

    cam.PopModelMatrix()

    if not _stars then _GenerateStars() end
    if not _starMat then _starMat = Material("star.png", "smooth unlitgeneric") end

    local obj = LocalPlayer():GetShip():GetObject()

    local x, y = obj:GetCoordinates()

    local pos = Vector((x - 8) * 16, (8 - y) * 16, 0)

    cam.Start3D(Vector(0, 0, 0), EyeAngles())

    render.SetMaterial(_starMat)
    for _, star in ipairs(_stars) do
        star:Render(pos, nil)
    end

    cam.End3D()
end

