sys = {}
sys._dict = {}

local _sysIndex = {}
_sysIndex.Name = "unnamed"
_sysIndex.Room = nil
_sysIndex.Ship = nil

function _sysIndex:Initialize()
	return
end

function _sysIndex:GetShip()
	return self.Room.Ship
end

if SERVER then
	function _sysIndex:StartControlling(screen, ply)
		return
	end
	
	function _sysIndex:StopControlling(screen, ply)
		return
	end
	
	function _sysIndex:ClickRoom(screen, ply, room)
		return
	end
	
	function _sysIndex:ClickDoor(screen, ply, door)
		return
	end
	
	function _sysIndex:GetScreens()
		return self.Room.Screens
	end
	
	function _sysIndex:Think(dt)
		return
	end
elseif CLIENT then
	_sysIndex.Icon = nil

	_sysIndex.DrawWholeShip = false

	_sysIndex.CanClickRooms = false
	_sysIndex.CanClickDoors = false

	function _sysIndex:Click(screen, x, y, button)
		return
	end
	
	function _sysIndex:ClickRoom(screen, room, button)
		net.Start("SysSelectRoom")
			net.WriteEntity(screen)
			net.WriteEntity(LocalPlayer())
			if room then
				net.WriteString(room:GetName())
			else
				net.WriteString("")
			end
			net.WriteInt(button, 8)
		net.SendToServer()
	end
	
	function _sysIndex:ClickDoor(screen, door, button)
		net.Start("SysSelectDoor")
			net.WriteEntity(screen)
			net.WriteEntity(LocalPlayer())
			net.WriteInt(table.KeyFromValue(screen.Ship.Doors, door), 8)
			net.WriteInt(button, 8)
		net.SendToServer()
	end
	
	function _sysIndex:GetRoomColor(screen, room, mouseOver)
		local r, g, b = 32, 32, 32
		if mouseOver then
			r, g, b = r + 32, g + 32, b + 32
		end
		--[[
		if room == screen.Room then
			local add = math.sin(CurTime() * math.pi * 2) / 2 + 0.5
			r, g, b = r + add * 32, g + add * 64, b
		end
		]]--
		return Color(r, g, b, 255)
	end
	
	function _sysIndex:GetDoorColor(screen, door, mouseOver)
		local c = 32
		if mouseOver then
			c = c + 32
		end
		if not door.Open then
			c = c + 127
			
			if door.Locked then
				return Color(c + 64, c - 64, c - 64, 255)
			end
		elseif door.Locked then
			return Color(c, c + 64, c, 255)
		end
		return Color(c, c, c, 255)
	end

	function _sysIndex:DrawGUI(screen)		
		if self.DrawWholeShip then		  
			local margin = 16
			screen:DrawShip(screen.Ship, -screen.Width / 2 + margin + 128, -screen.Height / 2 + margin + 64,
				512 - margin * 2, 256 - margin * 2)
		end

		screen:DrawCursor()
	end
end

if SERVER then
	util.AddNetworkString("SysSelectRoom")
	util.AddNetworkString("SysSelectDoor")
	
	net.Receive("SysSelectRoom", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local roomName = net.ReadString()
		
		if screen.Room.System then
			if string.len(roomName) > 0 then
				screen.Room.System:ClickRoom(screen, ply, ships.FindRoomByName(roomName))
			else
				screen.Room.System:ClickRoom(screen, ply, nil)
			end
		end
	end)
	
	net.Receive("SysSelectDoor", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local doorId = net.ReadInt(8)
		
		if screen.Room.System then
			screen.Room.System:ClickDoor(screen, ply, screen.Room.Ship.Doors[doorId])
		end
	end)
end

MsgN("Loading systems...")
local files = file.Find("finalfrontier/gamemode/systems/*.lua", "LUA")
for i, file in ipairs(files) do	
	local name = string.sub(file, 0, string.len(file) - 4)
	MsgN("  Loading system " .. name)

	if SERVER then AddCSLuaFile("systems/" .. file) end
	
	SYS = { Name = name }
	setmetatable(SYS, { __index = _sysIndex })
	include("systems/" .. file)
	
	sys._dict[name] = SYS
	SYS = nil
end

function sys.Create(name, room)
	if string.len(name) == 0 then return nil end
	if sys._dict[name] then
		local system = { Room = room, Ship = room.Ship, Base = _sysIndex }
		setmetatable(system, { __index = sys._dict[name] })
		system:Initialize()
		return system
	end
	return nil
end
