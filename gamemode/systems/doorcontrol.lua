SYS.FullName = "Door Control"

function SYS:Initialize()

end

if SERVER then
	function SYS:ClickDoor( screen, ply, door )
		if door:IsClosed() then
			door:LockOpen()
		else
			door:UnlockClose()
		end
	end
	
	function SYS:Think( dt )
		
	end
elseif CLIENT then
	SYS.DrawWholeShip = true
	SYS.CanClickDoors = true
	
	function SYS:GetRoomColor( screen, room, mouseOver )
		return Color( 32, 32, 32, 255 )
	end
end
