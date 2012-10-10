if SERVER then AddCSLuaFile( "shared.lua" ) end

local UPDATE_FREQ = 0.5
local CURSOR_UPDATE_FREQ = 0.25
local MAX_USE_DISTANCE = 64

ENT.Type = "anim"
ENT.Base = "base_anim"
	
ENT.Ship = nil
ENT.Room = nil

if SERVER then
	util.AddNetworkString( "CursorPos" )
	
	ENT.RoomName = nil

	function ENT:KeyValue( key, value )
		if key == "room" then
			self.RoomName = tostring( value )
		elseif key == "size" then
			local split = string.Explode( " ", tostring( value ) )
			if #split >= 1 then self:SetNWFloat( "width", tonumber( split[ 1 ] ) ) end
			if #split >= 2 then self:SetNWFloat( "height", tonumber( split[ 2 ] ) ) end
		end
	end
	
	function ENT:Initialize()
		self:DrawShadow( false )
	end

	function ENT:InitPostEntity()
		if self.RoomName then
			local rooms = ents.FindByName( self.RoomName )
			if #rooms > 0 then
				self.Room = rooms[ 1 ]
				self.Room:AddScreen( self )
			end
		end
		
		if not self.Room then
			Error( "Screen at " .. tostring( self:GetPos() ) .. " (" .. self:GetName() .. ") has no room!\n" )
			return
		end
		
		self:SetNWBool( "used", false )
		self:SetNWEntity( "user", nil )
		self:SetNWString( "ship", self.Room.ShipName )
		self:SetNWString( "room", self.RoomName )
	end
	
	function ENT:Think()
		if self:GetNWBool( "used" ) then
			local ply = self:GetNWEntity( "user" )
			if not ply:IsValid() or self:GetPos():Distance( ply:EyePos() ) > MAX_USE_DISTANCE then
				self:StopUsing()
			end
		end
	end
	
	function ENT:Use( activator, caller )
		if activator:IsPlayer() then
			if not self:GetNWBool( "used" ) and self:GetPos():Distance( activator:EyePos() ) <= MAX_USE_DISTANCE then
				self:StartUsing( activator )
			elseif self:GetNWEntity( "user" ) == activator then
				self:StopUsing()
			end
		end
	end
	
	function ENT:StartUsing( ply )
		self:SetNWBool( "used", true )
		self:SetNWEntity( "user", ply )
		ply:SetNWBool( "usingScreen", true )
		ply:SetNWEntity( "screen", self )
		ply:SetNWEntity( "oldWep", ply:GetActiveWeapon() )
		
		ply:SetWalkSpeed( 50 )
		ply:SetCanWalk( false )
		ply:CrosshairDisable()
		ply:Give( "weapon_ff_unarmed" )
		ply:SelectWeapon( "weapon_ff_unarmed" )
		
		if self.Room.System then
			self.Room.System:StartControlling( self, ply )
		end
	end
	
	function ENT:StopUsing()
		self:SetNWBool( "used", false )
		
		local ply = self:GetNWEntity( "user" )
		if ply:IsValid() then
			ply:SetNWBool( "usingScreen", false )
			local oldWep = ply:GetNWEntity( "oldWep" )
			
			ply:StripWeapon( "weapon_ff_unarmed" )
			if oldWep and oldWep:IsValid() then
				ply:SetActiveWeapon( oldWep )
			end
			
			ply:SetWalkSpeed( 175 )
			ply:SetCanWalk( true )
			ply:CrosshairEnable()
		end
		
		if self.Room.System then
			self.Room.System:StopControlling( self, ply )
		end
	end
	
	net.Receive( "CursorPos", function( len )
		local screen = net.ReadEntity()		
		screen:SetNWFloat( "curx", net.ReadFloat() )
		screen:SetNWFloat( "cury", net.ReadFloat() )
	end )
elseif CLIENT then
	SCREEN_DRAWSCALE = 16

	surface.CreateFont( "CTextSmall", {
		font = "consolas",
		size = 32,
		weight = 400,
		antialias = true
	} )
	
	surface.CreateFont( "CTextLarge", {
		font = "consolas",
		size = 64,
		weight = 400,
		antialias = true
	} )
	
	ENT.Width = nil
	ENT.Height = nil
	
	ENT._dialRadius = 0
	ENT._atmoCircle = nil
	ENT._shldCircle = nil
	ENT._innerCircle = nil
	
	ENT._using = false
	
	ENT._lastCursorUpdate = 0
	ENT._cursorx = 0
	ENT._cursory = 0
	ENT._lastCursorx = 0
	ENT._lastCursory = 0
	
	function ENT:Think()
		if not self.Ship and self:GetNWString( "ship" ) then
			self.Ship = ships.FindByName( self:GetNWString( "ship" ) )
			if self.Ship then
				self.Room = self.Ship.Rooms[ self:GetNWString( "room" ) ]
			end
		end
		
		if not self.Width and self:GetNWFloat( "width" ) then
			self.Width = self:GetNWFloat( "width" ) * SCREEN_DRAWSCALE
			self.Height = self:GetNWFloat( "height" ) * SCREEN_DRAWSCALE
		end
		
		if not self._using and self:GetNWBool( "used" ) and self:GetNWEntity( "user" ) == LocalPlayer() then
			self._using = true
		elseif self._using and ( not self:GetNWBool( "used" ) or self:GetNWEntity( "user" ) ~= LocalPlayer() ) then
			self._using = false
		end
	end

	function ENT:DrawStatusDial( x, y, radius )
		local atmo, temp, shld = 0, 0, 0
		if self.Room then
			atmo = self.Room:GetAtmosphere()
			temp = self.Room:GetTemperature() / 600
			shld = self.Room:GetShields()
		end
		
		local scale = radius / 192
		
		local innerRad = radius / 2
		local midRad = radius * 3 / 4
		
		if not self._atmoCircle or self._dialRadius ~= radius or atmo ~= self._atmoNew then
			self._atmoCircle = CreateHollowCircle( x, y, innerRad + 2 * scale, midRad - 2 * scale, -math.pi / 2, atmo * math.pi * 2 )
		end
		
		if not self._shldCircle or self._dialRadius ~= radius or shld ~= self._shldNew then
			self._shldCircle = CreateHollowCircle( x, y, midRad + 2 * scale, radius - 2 * scale, -math.pi / 2, shld * math.pi * 2 )
		end
		
		if not self._innerCircle or self._dialRadius ~= radius then
			self._innerCircle = CreateCircle( x, y, innerRad - 2 * scale )
		end
		
		self._dialRadius = radius
		
		surface.SetDrawColor( Color( 172, 45, 51, 255 ) )
		surface.DrawPoly( self._innerCircle )
		
		surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
		surface.DrawRect( x - radius / 2, y - radius / 2, radius, radius * ( 1 - temp ) )
		
		surface.SetDrawColor( Color( 45, 51, 172, 255 ) )
		for _, v in ipairs( self._shldCircle ) do
			surface.DrawPoly( v )
		end
		surface.SetDrawColor( Color( 51, 172, 45, 255 ) )
		for _, v in ipairs( self._atmoCircle ) do
			surface.DrawPoly( v )
		end
		
		surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		surface.DrawRect( x - 2 * scale, y - radius, 4 * scale, 286 * scale )
		
		for i = -4, 4 do
			if i ~= 0 then
				surface.DrawRect( x - 12 * scale, y + i * 16 * scale - 2 * scale, 24 * scale, 4 * scale )
			else
				surface.DrawRect( x - 24 * scale, y + i * 16 * scale - 2 * scale, 48 * scale, 4 * scale )
			end
		end
	end
	
	function ENT:TransformShip( ship, x, y, width, height )
		local bounds = Bounds( x, y, width, height )
		if not ship.Transform or not ship.TransformBounds:Equals( bounds ) then
			ship.TransformBounds = bounds
			ship.Transform = FindBestTransform( ship.Bounds, bounds, true, true )
		end
	end
	
	function ENT:DrawShip( ship, x, y, width, height )
		if not ship then return end
		
		local margin = 16
		self:TransformShip( ship, x, y, width, height )
		
		local mousePos = { x = self._cursorx, y = self._cursory }
		local last, lx, ly = nil, 0, 0
		
		for k, room in pairs( ship.Rooms ) do
			if not room.ShipTrans then
				room.ShipTrans = {}
				room.ShipTrans.Corners = {}
				for i, v in ipairs( room.Corners ) do
					local x, y = ship.Transform:Transform( v.x, v.y )
					room.ShipTrans.Corners[ i ] = { x = x, y = y }
				end
				room.ShipTrans.ConvexPolys = {}
				for j, poly in ipairs( room.ConvexPolys ) do
					room.ShipTrans.ConvexPolys[ j ] = {}
					for i, v in ipairs( poly ) do
						local x, y = ship.Transform:Transform( v.x, v.y )
						room.ShipTrans.ConvexPolys[ j ][ i ] = { x = x, y = y }
					end
				end
			end
			
			local color = self.Room.System:GetRoomColor( self, room,
				self.Room.System.CanClickRooms and
				IsPointInsidePolyGroup( room.ShipTrans.ConvexPolys, mousePos ) )
			
			-- local polyclrs = { Color( 255, 0, 0, 64 ), Color( 0, 255, 0, 64 ), Color( 0, 0, 255, 64 ) }
			
			for i, poly in ipairs( room.ShipTrans.ConvexPolys ) do
				surface.SetDrawColor( color )
				surface.DrawPoly( poly )
				
				--[[
				last = poly[ #poly ]
				lx, ly = last.x, last.y
				surface.SetDrawColor( polyclrs[ i ] )
				for __, v in ipairs( poly ) do
					surface.DrawLine( lx, ly, v.x, v.y )
					lx, ly = v.x, v.y
				end
				]]--
			end
			
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
			last = room.ShipTrans.Corners[ #room.ShipTrans.Corners ]
			lx, ly = last.x, last.y
			for _, v in ipairs( room.ShipTrans.Corners ) do
				surface.DrawLine( lx, ly, v.x, v.y )
				lx, ly = v.x, v.y
			end
		end
		
		for k, door in ipairs( ship.Doors ) do
			if not door.ShipTrans then
				door.ShipTrans = {}
				local coords = {
					{ x = -32, y = -64 },
					{ x = -32, y =  64 },
					{ x =  32, y =  64 },
					{ x =  32, y = -64 }
				}
				local trans = Transform2D()
				trans:Rotate( door.angle * math.pi / 180 )
				trans:Translate( door.x, door.y )
				for i, v in ipairs( coords ) do
					local x, y = ship.Transform:Transform( trans:Transform( v.x, v.y ) )
					door.ShipTrans[ i ] = { x = x, y = y }
				end
			end
			
			local color = self.Room.System:GetDoorColor( self, door,
				self.Room.System.CanClickDoors and
				IsPointInsidePoly( door.ShipTrans, mousePos ) )
			
			surface.SetDrawColor( color )
			surface.DrawPoly( door.ShipTrans )
			
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
			last = door.ShipTrans[ #door.ShipTrans ]
			lx, ly = last.x, last.y
			for _, v in ipairs( door.ShipTrans ) do
				surface.DrawLine( lx, ly, v.x, v.y )
				lx, ly = v.x, v.y
			end
		end
	end
	
	function ENT:FindCursorPosition()
		if self._using then
			local ang = self:GetAngles()
			local ply = LocalPlayer()
			local p0 = self:GetPos()
			local n = ang:Forward()
			local l0 = ply:GetShootPos()
			local l = ply:GetAimVector()
			
			local d = ( p0 - l0 ):Dot( n ) / l:Dot( n )
		
			local hitpos = ( l0 + l * d ) - p0
			local xvec = ang:Right()
			local yvec = ang:Up()
			
			self._cursorx = -hitpos:DotProduct( xvec ) * SCREEN_DRAWSCALE
			self._cursory = -hitpos:DotProduct( yvec ) * SCREEN_DRAWSCALE
			
			local curTime = CurTime()
			if ( curTime - self._lastCursorUpdate ) > CURSOR_UPDATE_FREQ then
				net.Start( "CursorPos" )
					net.WriteEntity( self )
					net.WriteFloat( self._cursorx )
					net.WriteFloat( self._cursory )
				net.SendToServer()
				self._lastCursorUpdate = curTime
			end
		else
			local cx = self:GetNWFloat( "curx" )
			local cy = self:GetNWFloat( "cury" )
			
			if cx ~= self._lastCursorx or cy ~= self._lastCursory then
				local t = ( CurTime() - self._lastCursorUpdate ) / CURSOR_UPDATE_FREQ
				
				if t >= 1 then
					self._lastCursorx = cx
					self._lastCursory = cy
					self._lastCursorUpdate = CurTime()
				else
					self._cursorx = self._lastCursorx + ( cx - self._lastCursorx ) * t
					self._cursory = self._lastCursory + ( cy - self._lastCursory ) * t
				end
			end
		end
	end
	
	function ENT:DrawCursor()
		local halfwidth = self.Width * 0.5
		local halfheight = self.Height * 0.5
		
		local boxSize = SCREEN_DRAWSCALE
		
		local x = self._cursorx
		local y = self._cursory
		
		x = math.Clamp( x, -halfwidth + boxSize * 0.5, halfwidth - boxSize * 0.5 )
		y = math.Clamp( y, -halfheight + boxSize * 0.5, halfheight - boxSize * 0.5 )
		
		surface.SetDrawColor( Color( 255, 255, 255, 64 ) )
		surface.DrawLine( x, -halfheight, x, halfheight )
		surface.DrawLine( -halfwidth, y, halfwidth, y )
		
		surface.SetDrawColor( Color( 255, 255, 255, 127 ) )
		surface.DrawOutlinedRect( x - boxSize * 0.5, y - boxSize * 0.5, boxSize, boxSize )
	end
	
	function ENT:Draw()
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )
		cam.Start3D2D( self:GetPos(), ang, 1 / SCREEN_DRAWSCALE )
			if not self:GetNWBool( "used" ) then
				self:DrawStatusDial( 0, 0, 192 )
			else
				self:FindCursorPosition()
				if self.Room and self.Room.System then
					self.Room.System:DrawGUI( self )
				else
					surface.SetTextColor( Color( 64, 64, 64, 255 ) )
					surface.SetFont( "CTextLarge" )
					surface.DrawCentredText( 0, 0, "NO SYSTEM INSTALLED" )
				end
			end
		cam.End3D2D()
	end
	
	function ENT:Click( ply )
		local mousePos = { x = self._cursorx, y = self._cursory }
		if self.Room and self.Room.System then
			local sys = self.Room.System
			if sys.CanClickRooms then
				for k, room in pairs( self.Ship.Rooms ) do
					if IsPointInsidePolyGroup( room.ShipTrans.ConvexPolys, mousePos ) then
						sys:ClickRoom( self, room )
						return
					end
				end
			end
			
			if sys.CanClickDoors then
				for k, door in pairs( self.Ship.Doors ) do
					if IsPointInsidePoly( door.ShipTrans, mousePos ) then
						sys:ClickDoor( self, door )
						return
					end
				end
			end
			
			sys:Click( self, mousePos.x, mousePos.y )
		end
	end
end
