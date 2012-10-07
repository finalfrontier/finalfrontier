SYS.FullName = "Shield Control"

function SYS:Initialize()

end

if SERVER then
	local SHIELD_POWER_PER_M2 = 0.01462

	util.AddNetworkString( "SysShieldSet" )
	
	net.Receive( "SysShieldSet", function( len )
		local screen = net.ReadEntity()
		local room = screen.Room.Ship._roomlist[ screen:GetNWInt( "CurRoom" ) ]
		local sys = screen.Room.System
		local distrib = math.Clamp( net.ReadFloat(), 0, 1 )
		sys.Distribution[ room ] = distrib
		screen:SetNWFloat( "CurValue", distrib )
	end )
	
	SYS.PowerUsage = nil
	SYS.Ditribution = nil
	
	function SYS:Initialize()
		self.Distribution = {}
	end
	
	function SYS:Think( dt )
		local totPower = 8
		local totNeeded = 0
		for _, room in ipairs( self.Ship._roomlist ) do
			totNeeded = totNeeded + room.SurfaceArea * SHIELD_POWER_PER_M2 * ( self.Distribution[ room ] or 0 )
		end
		
		local ratio = math.min( totPower / totNeeded, 1 )
		self.PowerUsage = totNeeded / totPower
		
		for _, room in ipairs( self.Ship._roomlist ) do
			room._shields = ( self.Distribution[ room ] or 0 ) * ratio
		end
	end
	
	function SYS:StartControlling( screen, ply )
		screen:SetNWInt( "CurRoom", 0 )
		screen:SetNWFloat( "CurValue", self.PowerUsage )
	end

	function SYS:ClickRoom( screen, ply, room )
		if not room or room.Index == screen:GetNWInt( "CurRoom" ) then
			screen:SetNWInt( "CurRoom", 0 )
			screen:SetNWFloat( "CurValue", self.PowerUsage )
		else
			screen:SetNWFloat( "CurValue", self.Distribution[ room ] or 0 )
			screen:SetNWInt( "CurRoom", room.Index )
		end
	end
elseif CLIENT then
	SYS.DrawWholeShip = true
	SYS.CanClickRooms = true
	
	SYS.CurRoom = nil
	
	function SYS:GetRoomColor( screen, room, mouseOver )
		local shields = math.Clamp( room:GetShields(), 0, 1 )
		local madd = 32
		if mouseOver then madd = 64 end
		if screen:GetNWInt( "CurRoom" ) == room.Index then
			local add = math.sin( CurTime() * math.pi * 2 ) / 2 + 0.5
			madd = madd + 32 * add + 32
		end
		return Color( madd, shields * ( 255 - 192 ) + madd, shields * ( 255 - 128 ) + madd, 255 )
	end
	
	function SYS:Click( screen, x, y )
		local roomIndex = screen:GetNWInt( "CurRoom" )
		if roomIndex > 0 and screen.PowerBar then
			local room = screen.Ship._roomlist[ roomIndex ]
			if screen.PowerBar:Click( x, y ) then
				net.Start( "SysShieldSet" )
					net.WriteEntity( screen )
					net.WriteFloat( screen.PowerBar.Value )
				net.SendToServer()
			elseif y < screen.PowerBar.Y - 16 then
				self:ClickRoom( screen, nil )
			end
		end
	end
	
	function SYS:DrawGUI( screen )
		local roomIndex = screen:GetNWInt( "CurRoom" )
		if roomIndex > 0 then
			if screen.UsageBar then
				screen.UsageBar = nil
			end
			
			local room = screen.Ship._roomlist[ roomIndex ]
			
			if not screen.PowerBar then
				screen.PowerBar = Slider()
				screen.PowerBar.X = -64
				screen.PowerBar.Y = screen.Height / 2 - 80
				screen.PowerBar.Height = 32
				screen.PowerBar.Width = 384
			end
			
			if room ~= screen.CurRoom or LocalPlayer() ~= screen:GetNWEntity( "user" ) then
				screen.CurRoom = room
				if screen.PowerBar then
					screen.PowerBar.Value = screen:GetNWFloat( "CurValue" )
				end
			end
		
			surface.SetTextColor( Color( 127, 127, 127, 255 ) )
			surface.SetFont( "CTextSmall" )
			
			surface.DrawCentredText( -screen.Width / 2 + 128, screen.Height / 2 - 96,
				"INTEGRITY" )
			
			surface.DrawCentredText( 128, screen.Height / 2 - 96,
				"POWER DISTRIBUTION" )
			
			local shields = room:GetShields()
			local clr = Color( 32, shields * ( 255 - 192 ) + 32, shields * ( 255 - 128 ) + 32, 255 )
			surface.SetTextColor( clr )
			surface.SetFont( "CTextLarge" )
			surface.DrawCentredText( -screen.Width / 2 + 128, screen.Height / 2 - 64,
				FormatNum( shields * 100, 3, 1 ) .. "%" )
			
			screen.PowerBar.Color = clr
			screen.PowerBar:Draw( screen )
		else
			if screen.PowerBar then
				screen.PowerBar = nil
				screen.CurRoom = nil
			end
			
			if not screen.UsageBar then
				screen.UsageBar = Slider()
				screen.UsageBar.X = -screen.Width / 2 + 64
				screen.UsageBar.Y = screen.Height / 2 - 80
				screen.UsageBar.Height = 32
				screen.UsageBar.Width = screen.Width - 128
			end
			
			local usage = screen:GetNWFloat( "CurValue" )
			screen.UsageBar.Value = usage
		
			surface.SetTextColor( Color( 127, 127, 127, 255 ) )
			surface.SetFont( "CTextSmall" )
			
			surface.DrawCentredText( 0, screen.Height / 2 - 96,
				"POWER USAGE (" .. FormatNum( usage * 100, 3, 1 ) .. "%)" )
			
			if usage < 1 then
				screen.UsageBar.Color = Color( 0, usage * 255, ( 1 - usage ) * 255, 255 )
			else
				screen.UsageBar.Color = Color( math.min( usage - 1, 1 ) * 255, math.max( 2 - usage, 0 ) * 255, 0, 255 )
			end
			
			screen.UsageBar:Draw( screen )
		end
		
		self.Base.DrawGUI( self, screen )
	end
end
