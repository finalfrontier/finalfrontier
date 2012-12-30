local RECHARGE_RATE = 1 / 60.0

SYS.FullName = "Shield Control"

function SYS:Initialize()

end

if SERVER then
	resource.AddFile("materials/systems/shields.png")

	local SHIELD_POWER_PER_M2 = 0.01462

	util.AddNetworkString("SysShieldSet")
	
	net.Receive("SysShieldSet", function(len)
		local screen = net.ReadEntity()
		local room = screen.Room.Ship._roomlist[screen:GetNWInt("CurRoom")]
		local sys = screen.Room.System
		local distrib = math.Clamp(net.ReadFloat(), 0, 1)
		sys.Distribution[room] = distrib
		screen:SetNWFloat("CurValue", distrib)
	end)
	
	SYS.PowerUsage = nil
	SYS.Ditribution = nil
	
	function SYS:Initialize()
		self.Distribution = {}
	end
	
	function SYS:Think(dt)
		local totPower = 8
		local totNeeded = 0
		for _, room in ipairs(self.Ship._roomlist) do
			totNeeded = totNeeded + room.SurfaceArea * SHIELD_POWER_PER_M2 * (self.Distribution[room] or 0)
		end
		
		local ratio = math.min(totPower / totNeeded, 1)
		self.PowerUsage = totNeeded / totPower
		
		for _, room in ipairs(self.Ship._roomlist) do
			local val = (self.Distribution[room] or 0) * ratio
			if room._shields < val then
				room._shields = room._shields + RECHARGE_RATE * dt
			end

			if room._shields > val then
				room._shields = val
			end
		end
	end
	
	function SYS:StartControlling(screen, ply)
		screen:SetNWInt("CurRoom", 0)
		screen:SetNWFloat("CurValue", self.PowerUsage)
	end

	function SYS:ClickRoom(screen, ply, room)
		if not room or room.Index == screen:GetNWInt("CurRoom") then
			screen:SetNWInt("CurRoom", 0)
			screen:SetNWFloat("CurValue", self.PowerUsage)
		else
			screen:SetNWFloat("CurValue", self.Distribution[room] or 0)
			screen:SetNWInt("CurRoom", room.Index)
		end

		return true
	end
elseif CLIENT then
	SYS.Icon = Material("systems/shields.png", "smooth")

	SYS.DrawWholeShip = true
	SYS.CanClickRooms = true

	SYS.ShipMarginBottom = 96

	SYS.MarginBottom = 16
	
	SYS.CurRoom = nil
	
	function SYS.GetRoomColor(screen, room)
		local shields = math.Clamp(room:GetShields(), 0, 1)
		local madd = 32
		if screen:IsCursorInsideRoom(room) then madd = 64 end
		if screen:GetNWInt("CurRoom") == room.Index then
			local add = math.sin(CurTime() * math.pi * 2) / 2 + 0.5
			madd = madd + 32 * add + 32
		end
		return Color(madd, shields * (255 - 192) + madd, shields * (255 - 128) + madd, 255)
	end
	
	function SYS:Click(screen, x, y, button)
		local roomIndex = screen:GetNWInt("CurRoom")
		if roomIndex > 0 and screen.PowerBar then
			local room = screen.Ship._roomlist[roomIndex]
			if screen.PowerBar:Click(x, y) then
				net.Start("SysShieldSet")
					net.WriteEntity(screen)
					net.WriteFloat(screen.PowerBar.Value)
				net.SendToServer()
			elseif y < screen.PowerBar.Y - 16 then
				screen:ClickRoom(nil, button)
			end
		end
	end
	
	function SYS:DrawGUI(screen)
		local roomIndex = screen:GetNWInt("CurRoom")
		if roomIndex > 0 then
			if screen.UsageBar then
				screen.UsageBar = nil
			end
			
			local room = screen.Ship._roomlist[roomIndex]
			
			if not screen.PowerBar then
				screen.PowerBar = Slider()
				screen.PowerBar.Width = 384
				screen.PowerBar.Height = 32
				screen.PowerBar.X = -64
				screen.PowerBar.Y = screen.Height / 2 - screen.PowerBar.Height - self.MarginBottom
				screen.PowerBar.Snap = 20
			end
			
			if room ~= screen.CurRoom or LocalPlayer() ~= screen:GetNWEntity("user") then
				screen.CurRoom = room
				if screen.PowerBar then
					screen.PowerBar.Value = screen:GetNWFloat("CurValue")
				end
			end
		
			surface.SetTextColor(Color(127, 127, 127, 255))
			surface.SetFont("CTextSmall")
			
			surface.DrawCentredText(-screen.Width / 2 + 128, screen.PowerBar.Y - 16,
				"INTEGRITY")
			
			surface.DrawCentredText(128, screen.PowerBar.Y - 16,
				"POWER DISTRIBUTION")
			
			local shields = room:GetShields()
			local clr = Color(32, shields * (255 - 192) + 32, shields * (255 - 128) + 32, 255)
			surface.SetTextColor(clr)
			surface.SetFont("CTextLarge")
			surface.DrawCentredText(-screen.Width / 2 + 128, screen.PowerBar.Y + 16,
				FormatNum(shields * 100, 3, 1) .. "%")
			
			screen.PowerBar.Color = clr
			screen.PowerBar:Draw(screen)
		else
			if screen.PowerBar then
				screen.PowerBar = nil
				screen.CurRoom = nil
			end
			
			if not screen.UsageBar then
				screen.UsageBar = Slider()
				screen.UsageBar.Width = screen.Width - 128
				screen.UsageBar.Height = 32
				screen.UsageBar.X = -screen.Width / 2 + 64
				screen.UsageBar.Y = screen.Height / 2 - screen.UsageBar.Height - self.MarginBottom
			end
			
			local usage = screen:GetNWFloat("CurValue")
			screen.UsageBar.Value = usage
		
			surface.SetTextColor(Color(127, 127, 127, 255))
			surface.SetFont("CTextSmall")
			
			surface.DrawCentredText(0, screen.UsageBar.Y - 16,
				"POWER USAGE (" .. FormatNum(usage * 100, 3, 1) .. "%)")
			
			if usage < 1 then
				screen.UsageBar.Color = Color(32, 32 + (usage * (255 - 64)), 32, 255)
			else
				screen.UsageBar.Color = Color(32 + math.min(usage - 1, 1) * (255 - 64), 32 + math.max(2 - usage, 0) * (255 - 64), 32, 255)
			end
			
			screen.UsageBar:Draw(screen)
		end
		
		self.Base.DrawGUI(self, screen)
	end
end
