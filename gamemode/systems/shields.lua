SYS.FullName = "Shield Control"

function SYS:Initialize()

end

if SERVER then
	function SYS:Think( dt )
		
	end
elseif CLIENT then
	SYS.DrawWholeShip = true
	SYS.CanClickRooms = true
	
	function SYS:GetRoomColor( screen, room, mouseOver )
		local shields = math.Clamp( room:GetShields(), 0, 1 )
		local madd = 32
		if mouseOver then madd = 64 end
		return Color( madd, shields * ( 255 - 192 ) + madd, shields * ( 255 - 64 ) + madd, 255 )
	end
end
