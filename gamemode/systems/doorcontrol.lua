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
end
