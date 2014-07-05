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

if SERVER then AddCSLuaFile("sh_sgui.lua") end

local sgui_debug = nil

if SERVER then
    sgui_debug = CreateConVar("sv_sgui_debug", "0", { FCVAR_ARCHIVE }, "Enable SGUI debugging for server.")
elseif CLIENT then
    sgui_debug = CreateClientConVar("cl_sgui_debug", "0")
end

MOUSE1 = 1
MOUSE2 = 2

if not sgui then
    sgui = {}
    sgui._dict = {}
else return end

function sgui.IsDebug()
    return sgui_debug:GetBool()
end

function sgui.Log(elem, msg)
    if not sgui.IsDebug() then return end

    if not msg then
        print("[sgui] " .. elem)
    else
        print("[sgui@" .. elem:GetRoom():GetName() .. " #" .. elem:GetID() .. "] " .. msg)
    end
end

local _mt = {}
_mt.__index = _mt

_mt._id = 0
_mt._screen = nil

_mt.BaseName = nil
_mt.Base = nil

_mt.Name = nil

function _mt:GetID()
    return self._id
end

function _mt:GetScreen()
    return self._screen
end

function _mt:Initialize() return end
function _mt:Think() return end
function _mt:Click(x, y, button) return false end

if SERVER then
    function _mt:UpdateLayout(layout) return end
end

if CLIENT then
    surface.CreateFont("CTextTiny", {
        font = "consolas",
        size = 24,
        weight = 400,
        antialias = true
    })

    surface.CreateFont("CTextSmall", {
        font = "consolas",
        size = 32,
        weight = 400,
        antialias = true
    })

    surface.CreateFont("CTextMedium", {
        font = "consolas",
        size = 48,
        weight = 400,
        antialias = true
    })
    
    surface.CreateFont("CTextLarge", {
        font = "consolas",
        size = 64,
        weight = 400,
        antialias = true
    })

    function _mt:UpdateLayout(layout) return end
    function _mt:Draw() return end
end

MsgN("Loading sgui...")
local files = file.Find("finalfrontier/gamemode/sgui/*.lua", "LUA")
for i, file in ipairs(files) do
    local name = string.sub(file, 0, string.len(file) - 4)
    if SERVER then AddCSLuaFile("sgui/" .. file) end

    MsgN("- " .. name)

    GUI = { Name = name }
    GUI.__index = GUI
    GUI.Super = {}
    GUI.Super.__index = GUI.Super
    GUI.Super[name] = GUI
    include("sgui/" .. file)

    sgui._dict[name] = GUI
    GUI = nil
end

for _, GUI in pairs(sgui._dict) do
    if GUI.BaseName then
        GUI.Base = sgui._dict[GUI.BaseName]
        setmetatable(GUI, GUI.Base)
        setmetatable(GUI.Super, GUI.Base.Super)
    else
        setmetatable(GUI, _mt)
    end
end

function sgui.Create(parent, name)
    if sgui._dict[name] then
        local screen = parent
        if not parent.GetClass or parent:GetClass() ~= "info_ff_screen" then
            screen = parent:GetScreen()
        end

        local element = { _screen = screen }

        setmetatable(element, sgui._dict[name])

        if screen ~= parent then
            parent:AddChild(element)
        end

        element:Initialize()
        
        return element
    end
    return nil
end
