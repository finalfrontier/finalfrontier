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

local SPACE_SIZE = 256
local SPACE_SIZE_HALF = SPACE_SIZE / 2
local SPACE_CLIP_FAR = SPACE_SIZE_HALF
local SPACE_FADE_FAR = SPACE_CLIP_FAR * 0.9
local SPACE_CLIP_NEAR = 4
local SPACE_FADE_NEAR = 8
local SPACE_STAR_COUNT = 256

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

    if pos.x > SPACE_SIZE_HALF then
        pos.x = pos.x - SPACE_SIZE
    elseif pos.x <= -SPACE_SIZE_HALF then
        pos.x = pos.x + SPACE_SIZE
    end

    if pos.y > SPACE_SIZE_HALF then
        pos.y = pos.y - SPACE_SIZE
    elseif pos.y <= -SPACE_SIZE_HALF then
        pos.y = pos.y + SPACE_SIZE
    end

    local dist = pos:Length()
    local clr = self._clr

    if dist > SPACE_FADE_FAR then
        clr.a = math.Round(math.max(0, (SPACE_CLIP_FAR - dist) / (SPACE_CLIP_FAR - SPACE_FADE_FAR)) * 255)
    elseif dist < SPACE_FADE_NEAR then
        clr.a = math.Round(math.max(0, (dist - SPACE_CLIP_NEAR) / (SPACE_FADE_NEAR - SPACE_CLIP_NEAR)) * 255)
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

    for i = 1, SPACE_STAR_COUNT do
        local scale = math.pow(math.random(), 2) + 2
        local shift = math.random() * 2 - 1

        local pos = Vector(
            (math.random() - 0.5) * SPACE_SIZE,
            (math.random() - 0.5) * SPACE_SIZE,
            (math.random() - 0.5) * SPACE_SIZE_HALF)

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
    local w = universe:GetHorizontalSectors()
    local h = universe:GetVerticalSectors()

    local pos = Vector((x - w / 2) * (SPACE_SIZE / w), (h / 2 - y) * (SPACE_SIZE / h), 0)

    cam.Start3D(Vector(0, 0, 0), EyeAngles())

    render.SetMaterial(_starMat)
    for _, star in ipairs(_stars) do
        star:Render(pos, nil)
    end

    cam.End3D()
end

