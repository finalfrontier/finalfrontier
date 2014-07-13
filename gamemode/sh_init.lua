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

if SERVER then AddCSLuaFile("sh_init.lua") end

GM.Name = "Final Frontier"
GM.Author = "Metapyziks"
GM.Email = "metapyziks@gmail.com"
GM.Website = "https://github.com/finalfrontier"

-- Global Functions

function table.Where(table, pred)
    local copy = {}

    for i, v in ipairs(table) do
        if pred(v) then table.insert(copy, v) end
    end

    return copy
end

function table.Take(table, count)
    local copy = {}

    for i, v in ipairs(table) do
        count = count - 1
        if count < 0 then break end
        table.insert(copy, v)
    end

    return copy
end

function table.Min(table, selector)
    local minScore = 0
    local minValue = nil

    for _, value in pairs(table) do
        local score = selector(value)
        if minValue == nil or score < minScore then
            minScore = score
            minValue = value
        end
    end

    return minValue
end

function table.Max(table, selector)
    local maxScore = 0
    local maxValue = nil

    for _, value in pairs(table) do
        local score = selector(value)
        if maxValue == nil or score > maxScore then
            maxScore = score
            maxValue = value
        end
    end

    return maxValue
end

function math.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

function Pulse(period, phase)
    return (math.sin((CurTime() + (phase or 0)) * math.pi * 2 / period) + 1) * 0.5
end

function LerpColour(a, b, t)
    return Color(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
        a.a + (b.a - a.a) * t
    )
end

function FormatNum(num, leading, trailing)
    local mul = math.pow(10, trailing)
    num = math.Round(num * mul) / mul

    local str = tostring(num)
    local index = string.find(str, "%.")
    if not index then
        index = string.len(str)
        if trailing > 0 then
            str = str .. "." .. string.rep("0", trailing)
        end
    else
        local dec = string.len(str) - index
        if trailing > dec then
            str = str .. string.rep("0", trailing - dec)
        end
        index = index - 1
    end

    if index < leading then
        str = string.rep("0", leading - index) .. str
    end

    return str
end

function FormatBearing(angle)
    angle = 90 - angle
    angle = angle - math.floor(angle / 360) * 360
    return FormatNum(angle, 3, 0)
end

function WrapAngle(ang, alwaysPositive)
    if not alwaysPositive then ang = ang + math.pi end
    ang = ang - math.floor(ang / (math.pi * 2)) * math.pi * 2
    if not alwaysPositive then ang = ang - math.pi end
    return ang
end

function FindAngleDifference(a, b)
    return WrapAngle(b - a, false)
end

-- TODO: Add check to avoid complex polys in output
function FindConvexPolygons(poly, output)
    output = output or {}
    local cur = {}
    local l = poly[#poly]
    local n = poly[1]
    local i = 1
    while i <= #poly do
        local v = n
        table.insert(cur, v)
        n = poly[(i % #poly) + 1]
        i = i + 1
        
        local la = math.atan2(l.y - v.y, l.x - v.x)
        local subPoly = { v }
        
        while n ~= v do
            table.insert(subPoly, n)
            if i > #poly + 1 then
                table.remove(cur, 1)
            end
            local na = math.atan2(n.y - v.y, n.x - v.x)
            local ang = WrapAngle(na - la, true)
            
            if ang > math.pi then
                n = poly[(i % #poly) + 1]
                i = i + 1
            else
                if #subPoly > 2 then
                    FindConvexPolygons(subPoly, output)
                end
                break
            end
        end
        
        if n == v then
            break
        end
        l = v
    end
    table.insert(output, cur)
    return output
end

function IsPointInsidePoly(poly, x, y)
    for i, v in ipairs(poly) do
        local n = poly[(i % #poly) + 1]
        local ax, ay = n.x - v.x, n.y - v.y
        local bx, by =   x - v.x,   y - v.y
        local cross = ax * by - ay * bx
        if CLIENT and cross < 0 then return false end -- uhhh
        if SERVER and cross > 0 then return false end -- yeah
    end
    
    return true
end

function IsPointInsidePolyGroup(polys, x, y)
    for _, poly in ipairs(polys) do
        if IsPointInsidePoly(poly, x, y) then return true end
    end
    
    return false
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetPermission(room)
    return self._permissions[room:GetPermissionsName()] or permission.NONE
end

function ply_mt:HasPermission(room, perm, ignoreSecurityCheck)
    return self:GetPermission(room) >= perm
        or (not ignoreSecurityCheck and not room:HasPlayerWithSecurityPermission())
end

function ply_mt:HasDoorPermission(door)
    return self:HasPermission(door:GetRooms()[1], permission.ACCESS)
        or self:HasPermission(door:GetRooms()[2], permission.ACCESS)
end
