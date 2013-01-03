if SERVER then AddCSLuaFile("sh_gui.lua") end

MOUSE1 = 1
MOUSE2 = 2

gui = {}
gui._dict = {}

local _mt = {}
_mt.__index = _mt

_mt.BaseName = nil
_mt.Base = nil

_mt.Screen = nil
_mt.Name = nil

function _mt:Initialize() return end
function _mt:Think() return end
function _mt:Click(x, y) return end

if SERVER then
	function _mt:UpdateLayout() end
end

if CLIENT then
	function _mt:UpdateLayout() end
	function _mt:Draw() return end
end

MsgN("Loading gui...")
local files = file.Find("finalfrontier/gamemode/gui/*.lua", "LUA")
for i, file in ipairs(files) do	
	local name = string.sub(file, 0, string.len(file) - 4)
	if SERVER then AddCSLuaFile("gui/" .. file) end

	MsgN("  Loading gui element " .. name)

	GUI = { Name = name }
	GUI.__index = GUI
	GUI.Super = {}
	GUI.Super.__index = GUI.Super
	GUI.Super[name] = GUI
	include("gui/" .. file)

	gui._dict[name] = GUI
	GUI = nil
end

for _, GUI in pairs(gui._dict) do
	if GUI.BaseName then
		GUI.Base = gui._dict[GUI.BaseName]
		setmetatable(GUI, GUI.Base)
		setmetatable(GUI.Super, GUI.Base.Super)
	else
		setmetatable(GUI, _mt)
	end
end

function gui.Create(parent, name)
	if gui._dict[name] then
		local screen = parent
		if not parent.GetClass or parent:GetClass() ~= "info_ff_screen" then
			screen = parent.Screen
		end

		local element = { Screen = screen }
		setmetatable(element, gui._dict[name])
		element:Initialize()

		if screen ~= parent then
			parent:AddChild(element)
		end
		return element
	end
end
