SYS.FullName = "Life Support"

function SYS:Initialize()

end

if SERVER then
	resource.AddFile("materials/systems/lifesupport.png")

	function SYS:ClickRoom(screen, ply, room)
		if room then
			room._airvolume = 0
			room.Ship:SendShipRoomStates(ply)
		end

		return true
	end
	
	function SYS:Think(dt)
		
	end
elseif CLIENT then
	SYS.Icon = Material("systems/lifesupport.png", "smooth")
	
	SYS.DrawWholeShip = true
	SYS.CanClickRooms = true
	
	function SYS:GetRoomColor(screen, room, mouseOver)
		local temp = math.Clamp(room:GetTemperature() / 300 - 1, -1, 1)
		local atmo = math.Clamp(room:GetAtmosphere(), 0, 1)
		local madd = 32
		if mouseOver then madd = 64 end
		if temp >= 0 then
			return Color(temp * atmo * (255 - 64) + madd, atmo * (255 - 64) + madd, madd, 255)
		else
			return Color(madd, atmo * (255 - 64) + madd, -temp * atmo * (255 - 64) + madd, 255)
		end
	end
end
