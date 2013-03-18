if SERVER then AddCSLuaFile("sh_systems.lua") end

permission = {}
permission.NONE 	= 0
permission.ACCESS	= 1
permission.SYSTEM 	= 2
permission.SECURITY = 3

if not sys then
	sys = {}
	sys._dict = {}
	sys._loaded = false
end

local _mt = {}
_mt.__index = _mt

_mt.Name = "unnamed"
_mt.Room = nil
_mt.Ship = nil
_mt.Powered = false

_mt.SGUIName = "page"

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
	
	function _mt:GetScreens()
		return self.Room.Screens
	end
	
	function _mt:Think(dt)
		return
	end
elseif CLIENT then
	_mt.Icon = Material("systems/noicon.png", "smooth")
end

--function sys.Load()
	if sys._loaded then return end
	sys._loaded = true

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
--end

function sys.GetAll()
	return sys._dict
end

function sys.Create(name, room)
	--if not sys._loaded then sys.Load() end

	if string.len(name) == 0 then return nil end
	if sys._dict[name] then
		local system = { Room = room, Ship = room.Ship, Base = _mt }
		setmetatable(system, sys._dict[name])
		system:Initialize()
		return system
	end
	return nil
end
