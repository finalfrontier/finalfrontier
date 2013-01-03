if SERVER then AddCSLuaFile("sh_systems.lua") end

sys = {}
sys._dict = {}

local _mt = {}
_mt.__index = _mt

_mt.Name = "unnamed"
_mt.Room = nil
_mt.Ship = nil

function _mt:Initialize()
	return
end

function _mt:GetShip()
	return self.Room.Ship
end

if SERVER then
	resource.AddFile("materials/systems/noicon.png")

	function _mt:StartControlling(screen, ply)
		return
	end
	
	function _mt:StopControlling(screen, ply)
		return
	end
	
	function _mt:ClickRoom(screen, ply, room)
		return true
	end
	
	function _mt:ClickDoor(screen, ply, door)
		return true
	end
	
	function _mt:GetScreens()
		return self.Room.Screens
	end
	
	function _mt:Think(dt)
		return
	end
elseif CLIENT then
	_mt.Icon = Material("systems/noicon.png", "smooth")

	_mt.DrawWholeShip = false
	_mt.ShipMarginLeft = 24
	_mt.ShipMarginTop = 24
	_mt.ShipMarginRight = 24
	_mt.ShipMarginBottom = 24

	_mt.CanClickRooms = false
	_mt.CanClickDoors = false

	function _mt:NewSession(screen)
		self._shipTransform = self.Ship:FindTransform(screen,
			-screen.Width / 2 + self.ShipMarginLeft,
			-screen.Height / 2 + self.ShipMarginTop + 64,
			screen.Width - self.ShipMarginLeft - self.ShipMarginRight,
			screen.Height - self.ShipMarginTop - self.ShipMarginBottom - 64)
	end

	function _mt:Click(screen, x, y, button)
		return
	end
	
	function _mt.GetDoorColor(screen, door)
		return screen:GetDoorColor(door, true)
	end

	function _mt.GetRoomColor(screen, room)
		local r, g, b = 32, 32, 32
		if screen.Room.System.CanClickRooms and screen.IsCursorInsideRoom(room) then
			r, g, b = r + 32, g + 32, b + 32
		end
		return Color(r, g, b, 255)
	end

	function _mt:DrawGUI(screen)
		if self.DrawWholeShip then
			self.Ship:ApplyTransform(self._shipTransform)
			self.Ship:Draw(screen, self.GetRoomColor, self.GetDoorColor)
		end
	end
end

MsgN("Loading systems...")
local files = file.Find("finalfrontier/gamemode/systems/*.lua", "LUA")
for i, file in ipairs(files) do	
	local name = string.sub(file, 0, string.len(file) - 4)
	MsgN("  Loading system " .. name)

	if SERVER then AddCSLuaFile("systems/" .. file) end
	
	SYS = setmetatable({ Name = name }, _mt)
	SYS.__index = SYS
	include("systems/" .. file)
	
	sys._dict[name] = SYS
	SYS = nil
end

function sys.Create(name, room)
	if string.len(name) == 0 then return nil end
	if sys._dict[name] then
		local system = { Room = room, Ship = room.Ship, Base = _mt }
		setmetatable(system, sys._dict[name])
		system:Initialize()
		return system
	end
	return nil
end
