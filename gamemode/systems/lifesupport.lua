SYS.FullName = "Life Support"

function SYS:Initialize()

end

if SERVER then
	function SYS:Think( dt )
		self.Room._temperature = 298
		self.Room._airvolume = self.Room.Volume
	end
elseif CLIENT then
	SYS.DrawWholeShip = true
	SYS.CanClickRooms = true
	
	function SYS:GetRoomColor( screen, room, mouseOver )
		local temp = math.Clamp( room:GetTemperature() / 300 - 1, -1, 1 )
		local atmo = math.Clamp( room:GetAtmosphere(), 0, 1 )
		local madd = 32
		if mouseOver then madd = 64 end
		if temp >= 0 then
			return Color( temp * ( 255 - 64 ) + madd, atmo * ( 1 - temp ) * ( 255 - 64 ) + madd, madd, 255 )
		else
			return Color( madd, atmo * ( 1 + temp ) * ( 255 - 64 ) + madd, -temp * ( 255 - 64 ) + madd, 255 )
		end
	end
end
