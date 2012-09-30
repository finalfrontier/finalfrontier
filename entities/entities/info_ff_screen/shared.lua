if SERVER then AddCSLuaFile( "shared.lua" ) end

local UPDATE_FREQ = 0.5
local MAX_USE_DISTANCE = 64

ENT.Type = "anim"
ENT.Base = "base_anim"
	
ENT._lastupdate = 0

if SERVER then
	ENT.RoomName = nil
	ENT.Room = nil
	
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
		
		self:UpdateRoomProperties()
		self:SetNWBool( "used", false )
		self:SetNWEntity( "user", nil )
		self:SetNWString( "ship", self.Room.ShipName )
		self:SetNWString( "room", self.RoomName )
	end
	
	function ENT:UpdateRoomProperties()
		self:SetNWFloat( "temp", self.Room:GetTemperature() )
		self:SetNWFloat( "atmo", self.Room:GetAtmosphere() )
		self:SetNWFloat( "shld", self.Room:GetMaxShield() )
		
		self._lastupdate = CurTime()
	end
	
	function ENT:Think()
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ then
			self:UpdateRoomProperties()
		end
		
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
		
		ply:SetWalkSpeed( 50 )
		ply:SetCanWalk( false )
		ply:SelectWeapon( "weapon_ff_unarmed" )
		ply:GetWeapon( "weapon_ff_unarmed" ):SetWeaponHoldType( "pistol" )
	end
	
	function ENT:StopUsing()
		self:SetNWBool( "used", false )
		
		local ply = self:GetNWEntity( "user" )
		if ply:IsValid() then
			ply:SetWalkSpeed( 250 )
			ply:SetCanWalk( true )
		end
	end
elseif CLIENT then
	local DRAWSCALE = 16

	surface.CreateFont( "CTextSmall", {
		font = "consolas",
		size = 32,
		weight = 400,
		scanlines = 2,
		antialias = false
	} )
	
	surface.CreateFont( "CTextLarge", {
		font = "consolas",
		size = 32,
		weight = 400,
		scanlines = 2,
		antialias = false
	} )
	
	ENT._dialRadius = 0
	ENT._tempOld = 0
	ENT._tempNew = 0
	ENT._atmoOld = 0
	ENT._atmoNew = 0
	ENT._atmoCircle = nil
	ENT._shldOld = 0
	ENT._shldNew = 0
	ENT._shldCircle = nil
	ENT._innerCircle = nil
	
	ENT._using = false
	
	ENT._mousex = 0
	ENT._mousey = 0
	
	function ENT:Think()
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ then
			self:UpdateDisplay()
		end
		
		if not self._using and self:GetNWBool( "used" ) and self:GetNWEntity( "user" ) == LocalPlayer() then
			self._using = true
		elseif self._using and ( not self:GetNWBool( "used" ) or self:GetNWEntity( "user" ) ~= LocalPlayer() ) then
			self._using = false
		end
	end
	
	function ENT:UpdateDisplay()
		self._tempOld = self._tempNew
		self._tempNew = math.min( self:GetNWFloat( "temp" ) / 600, 1 )
		self._atmoOld = self._atmoNew
		self._atmoNew = self:GetNWFloat( "atmo" )
		self._shldOld = self._shldNew
		self._shldNew = self:GetNWFloat( "shld" )
		
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ * 2 then
			self._tempOld = self._tempNew
			self._atmoOld = self._atmoNew
			self._shldOld = self._shldNew
			self._lastupdate = CurTime()
		elseif self._tempOld ~= self._tempNew or self._atmoOld ~= self._atmoNew or self._shldOld ~= self._shldNew then
			self._lastupdate = CurTime()
		end
	end

	function ENT:DrawStatusDial( x, y, radius )
		local t = ( CurTime() - self._lastupdate ) / UPDATE_FREQ
		
		local atmo = self._atmoOld + ( self._atmoNew - self._atmoOld ) * t
		local temp = self._tempOld + ( self._tempNew - self._tempOld ) * t
		local shld = self._shldOld + ( self._shldNew - self._shldOld ) * t
		
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
	
	function ENT:DrawShip( name )
		local ship = Ships.FindByName( name )
		if not ship then return end
		
		if not ship.Transform then
			local width, height = self:GetNWFloat( "width" ) * DRAWSCALE,
								  self:GetNWFloat( "height" ) * DRAWSCALE
								  
			local margin = 16
			ship.Transform = FindBestTransform( ship.Bounds,
				Bounds( -width / 2 + margin, -height / 2 + margin,
					width - margin * 2, height - margin * 2 ),
				true, true )
		end
		
		local thisRoomName = self:GetNWString( "room" )
		
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
			
			local color = Color( 32, 32, 32, 255 )			
			local mousePos = { x = self._mousex * DRAWSCALE, y = self._mousey * DRAWSCALE }
			
			if IsPointInsidePolyGroup( room.ShipTrans.ConvexPolys, mousePos ) then
				color = Color( 64, 64, 64, 255 )
			end
			
			if room.Name == thisRoomName then
				local add = math.sin( CurTime() * math.pi * 2 ) / 2 + 0.5
				color = Color( color.r + add * 32, color.g + add * 64, color.b, color.a )
			end
			
			-- local polyclrs = { Color( 255, 0, 0, 64 ), Color( 0, 255, 0, 64 ), Color( 0, 0, 255, 64 ) }
			
			local last, lx, ly = nil, 0, 0
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
	end
	
	function ENT:DrawCursor()
		local halfwidth = self:GetNWFloat( "width" ) * DRAWSCALE * 0.5
		local halfheight = self:GetNWFloat( "height" ) * DRAWSCALE * 0.5
		
		local x = self._mousex * DRAWSCALE
		local y = self._mousey * DRAWSCALE
		
		if x >= -halfwidth and x < halfwidth and y >= - halfheight and y < halfheight then
			surface.SetDrawColor( Color( 255, 255, 255, 64 ) )
			surface.DrawLine( x, -halfheight, x, halfheight )
			surface.DrawLine( -halfwidth, y, halfwidth, y )
			
			surface.SetDrawColor( Color( 255, 255, 255, 127 ) )
			surface.DrawOutlinedRect( x - DRAWSCALE * 0.5, y - DRAWSCALE * 0.5, DRAWSCALE, DRAWSCALE )
		end
	end
	
	function ENT:FindCursorPosition()
		local ply = LocalPlayer()
		local trace = {}
		trace.start = ply:GetShootPos()
		trace.endpos = trace.start + ply:GetAimVector() * 80
		trace.mask = MASK_SOLID_BRUSHONLY
		
		local result = util.TraceLine( trace )
		if result.Hit then
			local hitpos = result.HitPos - self:GetPos()
			local ang = self:GetAngles()
			local xvec = ang:Right()
			local yvec = ang:Up()
			
			self._mousex = -hitpos:DotProduct( xvec )
			self._mousey = -hitpos:DotProduct( yvec )
		end
	end
	
	function ENT:Draw()
		if self._using then
			self:FindCursorPosition()
		end
	
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )
		cam.Start3D2D( self:GetPos(), ang, 1 / DRAWSCALE )
			if not self:GetNWBool( "used" ) then
				self:DrawStatusDial( 0, 0, 192 )
			else
				self:DrawStatusDial( -320, -160, 48 )
				self:DrawShip( self:GetNWString( "ship" ) )
				
				self:DrawCursor()
			end
		cam.End3D2D()
	end
end
