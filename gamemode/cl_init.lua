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

include("gmtools/nwtable.lua")

include("player_class/player_ff_default.lua")

include("sh_init.lua")
include("sh_bounds.lua")
include("sh_matrix.lua")
include("sh_transform2d.lua")
include("sh_weapons.lua")
include("sh_sgui.lua")
include("sh_systems.lua")
include("cl_door.lua")
include("cl_room.lua")
include("cl_ship.lua")
include("cl_ships.lua")
include("sh_teams.lua")
include("cl_universe.lua")
include("cl_scoreboard.lua")
include("cl_skypaint.lua")

WHITE = Material("vgui/white")
CIRCLE = Material("circle.png", "smooth")
PLAYER_DOT = Material("playerdot.png", "smooth")
SHIP_ICON = Material("objects/ship.png", "smooth")
MISSILE_ICON = Material("objects/missile.png", "smooth")
POWER = Material("power.png", "smooth")

-- Global Functions

function math.sign(value)
    if value < 0 then return -1 end
    if value > 0 then return  1 end
    return 0
end

local sin, cos = math.sin, math.cos
function CreateCircle(x, y, radius)
    local quality = math.min(256, 4 * math.sqrt(radius) + 8)
    local verts = {}
    local ang = 0
    for i = 1, quality do
        ang = i * math.pi * 2 / quality
        verts[i] = { x = x + cos(ang) * radius, y = y + sin(ang) * radius }
    end
    return verts
end

function CreateHollowCircle(x, y, innerRadius, outerRadius, startAngle, rotation)
    rotation = math.min(rotation or (math.pi * 2), math.pi * 2)
    startAngle = startAngle or 0
    local quality = math.min(256, 4 * math.sqrt(outerRadius) + 8)
    local verts = {}
    local angA, angB
    local mul = math.pi * 2 / quality
    local count = quality * rotation / (math.pi * 2)
    for i = 0, count do
        angA = startAngle + i * mul
        angB = angA + mul
        if angB - startAngle > rotation then angB = startAngle + rotation end
        sinA, cosA = sin(angA), cos(angA)
        sinB, cosB = sin(angB), cos(angB)
        verts[i + 1] = {
            { x = x + cosA * innerRadius, y = y + sinA * innerRadius },
            { x = x + cosA * outerRadius, y = y + sinA * outerRadius },
            { x = x + cosB * outerRadius, y = y + sinB * outerRadius },
            { x = x + cosB * innerRadius, y = y + sinB * innerRadius }
        }
    end
    return verts
end

function surface.DrawCentredText(x, y, text)
    local wid, hei = surface.GetTextSize(text)
    surface.SetTextPos(x - wid / 2, y - hei / 2)
    surface.DrawText(text)
end

function surface.DrawCircle(x, y, radius)
    surface.SetMaterial(CIRCLE)
    surface.DrawTexturedRect(x - radius, y - radius, radius * 2, radius * 2)
    draw.NoTexture()
end

function surface.DrawPoints(points)
    for _, v in ipairs(points) do
        surface.DrawRect(v.x - 0.5, v.y - 0.5, 1, 1)
    end
end

local CONNECTOR = Material("connector.png", "smooth")
function surface.DrawConnector(sx, sy, ex, ey, width)
    local dx = ex - sx
    local dy = ey - sy
    local diff = math.sqrt(dx * dx + dy * dy)
    local ang = -math.atan2(dy, dx) / math.pi * 180
    surface.SetMaterial(CONNECTOR)
    surface.DrawTexturedRectRotated(sx + dx * 0.5, sy + dy * 0.5, diff, width, ang)
    draw.NoTexture()
end

-- Gamemode Overrides

function GM:Initialize()
    MsgN("Final Frontier client-side is initializing...")

    self.BaseClass:Initialize()
end

function GM:Think()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply ~= LocalPlayer() and not ply.dt then
            ply:InstallDataTable()
            SetupPlayerDataTables(ply)
        end
    end

    ships.Think()
    team.Think()
end

function GM:HUDWeaponPickedUp(weapon)
    if weapon:GetClass() == "weapon_ff_unarmed" then return end
    
    self.BaseClass:HUDWeaponPickedUp(weapon)
end

function GM:PlayerBindPress(ply, bind, pressed)
    if ply ~= LocalPlayer() then return end
    if ply:GetUsingScreen() then
        local screen = ply:GetCurrentScreen()
        if IsValid(screen) and screen.Click then
            if bind == "+attack" then
                screen:Click(MOUSE1)
            elseif bind == "+attack2" then
                screen:Click(MOUSE2)
            end
        end
    end
end

function GM:DrawDeathNotice(x, y)
    return false
end
