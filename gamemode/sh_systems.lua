sys = {}
sys._dict = {}

local _sysIndex = {}
_sysIndex.Name = "unnamed"
_sysIndex.Room = nil

function _sysIndex:Initialize()
	return
end

function _sysIndex:GetShip()
	return self.Room.Ship
end

if SERVER then
	function _sysIndex:ClickRoom( screen, ply, room )
		return
	end
	
	function _sysIndex:ClickDoor( screen, ply, door )
		return
	end
	
	function _sysIndex:GetScreens()
		return self.Room.Screens
	end
	
	function _sysIndex:Think( dt )
		return
	end
elseif CLIENT then
	_sysIndex.DrawWholeShip = false

	_sysIndex.CanClickRooms = false
	_sysIndex.CanClickDoors = false
	
	function _sysIndex:ClickRoom( screen, room )
		net.Start( "SysSelectRoom" )
			net.WriteEntity( screen )
			net.WriteEntity( LocalPlayer() )
			net.WriteString( room:GetName() )
		net.SendToServer()
	end
	
	function _sysIndex:ClickDoor( screen, door )
		net.Start( "SysSelectDoor" )
			net.WriteEntity( screen )
			net.WriteEntity( LocalPlayer() )
			net.WriteInt( table.KeyFromValue( screen.Ship.Doors, door ), 8 )
		net.SendToServer()
	end
	
	function _sysIndex:GetRoomColor( screen, room, mouseOver )
		local color = Color( 32, 32, 32, 255 )
		if mouseOver then
			color = Color( 64, 64, 64, 255 )
		end
		if room == screen.Room then
			local add = math.sin( CurTime() * math.pi * 2 ) / 2 + 0.5
			color = Color( color.r + add * 32, color.g + add * 64, color.b, color.a )
		end
		
		return color
	end

	function _sysIndex:DrawGUI( screen )		
		surface.SetTextColor( Color( 255, 255, 255, 255 ) )
		surface.SetFont( "CTextLarge" )
		surface.DrawCentredText( 0, -screen.Height / 2 + 32, string.upper( self.FullName ) )
		
		if self.DrawWholeShip then		  
			local margin = 16
			screen:DrawShip( screen.Ship, -screen.Width / 2 + margin + 128, -screen.Height / 2 + margin + 64,
				512 - margin * 2, 256 - margin * 2 )
		end
		
		screen:DrawCursor()
	end
end

if SERVER then
	util.AddNetworkString( "SysSelectRoom" )
	util.AddNetworkString( "SysSelectDoor" )
	
	net.Receive( "SysSelectRoom", function( len )
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local roomName = net.ReadString()
		
		if screen.Room.System then
			screen.Room.System:ClickRoom( screen, ply, ships.FindRoomByName( roomName ) )
		end
	end )
	
	net.Receive( "SysSelectDoor", function( len )
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local doorId = net.ReadInt( 8 )
		
		if screen.Room.System then
			screen.Room.System:ClickDoor( screen, ply, screen.Room.Ship.Doors[ doorId ] )
		end
	end )
end

MsgN( "Loading systems..." )
local files = file.Find( "finalfrontier/gamemode/systems/*.lua", "LUA" )
for i, file in ipairs( files ) do	
	local name = string.sub( file, 0, string.len( file ) - 4 )
	MsgN( "  Loading system " .. name )

	if SERVER then AddCSLuaFile( "systems/" .. file ) end
	
	SYS = { Name = name }
	setmetatable( SYS, { __index = _sysIndex } )
	include( "systems/" .. file )
	
	sys._dict[ name ] = SYS
	SYS = nil
end

function sys.Create( name, room )
	if string.len( name ) == 0 then return nil end
	if sys._dict[ name ] then
		local system = { Room = room, Base = _sysIndex }
		setmetatable( system, { __index = sys._dict[ name ] } )
		system:Initialize()
		return system
	end
	return nil
end
