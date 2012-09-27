if SERVER then AddCSLuaFile( "shared.lua" ) end

local UPDATE_FREQ = 0.5

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
				self:UpdateRoomProperties()
			end
		end
		
		if not self.Room then
			Error( "Sdreen at " .. tostring( self:GetPos() ) .. " (" .. self:GetName() .. ") has no room!\n" )
		end
	end
	
	function ENT:UpdateRoomProperties()
		self:SetNWFloat( "temperature", self.Room:GetTemperature() )
		self:SetNWFloat( "atmosphere", self.Room:GetPressure() )
		self:SetNWFloat( "maxshield", self.Room:GetMaxShield() )
		
		self._lastupdate = CurTime()
	end
	
	function ENT:Think()
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ then
			self:UpdateRoomProperties()
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
	
	ENT._shieldOld = 0
	ENT._shieldCircle = nil
	ENT._atmoOld = 0
	ENT._atmoNew = 0
	ENT._atmoCircle = nil
	ENT._tempOld = 0
	ENT._tempNew = 0
	ENT._innerCircle = CreateCircle( 0, 0, 94 )
	
	function ENT:Think()
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ then
			self:UpdateDisplay()
		end
	end
	
	function ENT:UpdateDisplay()
		self._atmoOld = self._atmoNew
		self._atmoNew = self:GetNWFloat( "atmosphere" )
		self._tempOld = self._tempNew
		self._tempNew = math.min( self:GetNWFloat( "temperature" ) / 600, 1 )
		
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ * 2 then
			self._atmoOld = self._atmoNew
			self._tempOld = self._tempNew
		end
		
		self._lastupdate = CurTime()
	end

	function ENT:Draw()
		local width = self:GetNWFloat( "width" ) * DRAWSCALE
		local height = self:GetNWFloat( "height" ) * DRAWSCALE
		
		local top = -height / 2
		local left = -width / 2
		
		local t = ( CurTime() - self._lastupdate ) / UPDATE_FREQ
			
		if not self._shieldCircle or self._shieldOld ~= self:GetNWFloat( "maxshield" ) then
			self._shieldOld = self._shieldOld + ( self:GetNWFloat( "maxshield" ) - self._shieldOld ) / 4
			self._shieldCircle = CreateHollowCircle( 0, 0, 146, 190, -math.pi / 2, math.pi * 3 / 5 )
		end
		
		local atmo = self._atmoOld + ( self._atmoNew - self._atmoOld ) * t
		local temp = self._tempOld + ( self._tempNew - self._tempOld ) * t
		
		if not self._atmoCircle or atmo ~= self._atmoNew then
			self._atmoCircle = CreateHollowCircle( 0, 0, 98, 142, -math.pi / 2, atmo * math.pi * 2 )
		end
	
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )
		cam.Start3D2D( self:GetPos(), ang, 1 / DRAWSCALE )
			surface.SetDrawColor( Color( 172, 45, 51, 255 ) )
			surface.DrawPoly( self._innerCircle )
			
			surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
			surface.DrawRect( -96, -96, 192, 192 * ( 1 - temp ) )
			
			surface.SetDrawColor( Color( 45, 51, 172, 255 ) )
			for _, v in ipairs( self._shieldCircle ) do
				surface.DrawPoly( v )
			end
			surface.SetDrawColor( Color( 51, 172, 45, 255 ) )
			for _, v in ipairs( self._atmoCircle ) do
				surface.DrawPoly( v )
			end
			
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
			surface.DrawRect( -2, -192, 4, 286 )
			
			for i = -4, 4 do
				if i ~= 0 then
					surface.DrawRect( -12, i * 16 - 2, 24, 4 )
				else
					surface.DrawRect( -24, i * 16 - 2, 48, 4 )
				end
			end
		cam.End3D2D()
	end
end
