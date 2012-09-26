if SERVER then AddCSLuaFile( "shared.lua" ) end

local UPDATE_FREQ = 0.5

ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	ENT.RoomName = nil
	ENT.Room = nil
	
	ENT._lastupdate = 0
	
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
		self:SetNWFloat( "pressure", self.Room:GetPressure() )
		self:SetNWFloat( "maxshield", self.Room:GetMaxShield() )
		
		self._lastupdate = CurTime()
	end
	
	function ENT:Think()
		if ( CurTime() - self._lastupdate ) > UPDATE_FREQ then
			self:UpdateRoomProperties()
		end
	end
elseif CLIENT then
	local DRAWSCALE = 8

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

	function ENT:Draw()
		local width = self:GetNWFloat( "width" ) * DRAWSCALE
		local height = self:GetNWFloat( "height" ) * DRAWSCALE
		
		local top = -height / 2
		local left = -width / 2
	
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )
		cam.Start3D2D( self:GetPos(), ang, 1 / DRAWSCALE )
			surface.SetTextColor( 255, 255, 255, 255 )
			surface.SetFont( "CTextSmall" )
			surface.SetTextPos( left + 16, top + 8 )
			surface.DrawText( "  Shield: 100.0%" )
			surface.SetTextPos( left + 16, top + 8 + 24 )
			surface.DrawText( "Pressure: " .. FormatNum( self:GetNWFloat( "pressure" ) / 1000, 3, 1 ) .. "kPa" )
			surface.SetTextPos( left + 16, top + 8 + 48 )
			surface.DrawText( "    Temp: " .. FormatNum( self:GetNWFloat( "temperature" ), 3, 1 ) .. "K" )
		cam.End3D2D()
	end
end
