if SERVER then AddCSLuaFile("sh_sgui.lua") end

DEBUG = false

MOUSE1 = 1
MOUSE2 = 2

sgui = {}
sgui._dict = {}

local _mt = {}
_mt.__index = _mt

_mt._id = 0

_mt.BaseName = nil
_mt.Base = nil

_mt.Screen = nil
_mt.Name = nil

function _mt:GetID()
	return self._id
end

function _mt:Initialize() return end
function _mt:Think() return end
function _mt:Click(x, y, button) return false end

if SERVER then
	function _mt:UpdateLayout(layout) return end
end

if CLIENT then
	function _mt:UpdateLayout(layout) return end
	function _mt:Draw() return end
end

MsgN("Loading sgui...")
local files = file.Find("finalfrontier/gamemode/sgui/*.lua", "LUA")
for i, file in ipairs(files) do	
	local name = string.sub(file, 0, string.len(file) - 4)
	if SERVER then AddCSLuaFile("sgui/" .. file) end

	MsgN("  Loading sgui element " .. name)

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
			screen = parent.Screen
		end

		local element = { Screen = screen }
		if SERVER then
			element._id = screen.NextGUIID
			screen.NextGUIID = screen.NextGUIID + 1
		end

		setmetatable(element, sgui._dict[name])

		if screen ~= parent then
			parent:AddChild(element)
		end

		element:Initialize()
		
		return element
	end
end
