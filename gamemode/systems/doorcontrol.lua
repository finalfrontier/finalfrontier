SYS.FullName = "Door Control"

function SYS:Initialize()

end

if SERVER then
	resource.AddFile("materials/systems/doorcontrol.png")

	util.AddNetworkString("SysDoorCloseAll")
	util.AddNetworkString("SysDoorOpenAll")
	util.AddNetworkString("SysDoorToggle")
	
	net.Receive("SysDoorCloseAll", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		
		for _, door in ipairs(screen.Room.Ship.Doors) do
			if screen:GetNWBool("lockMode") then
				door:Lock()
			elseif door:IsOpen() then
				door:UnlockClose()
			end
		end
		
		timer.Simple(0.1, function() screen.Room.Ship:SendShipRoomStates(ply) end)
	end)
	
	net.Receive("SysDoorOpenAll", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		
		for _, door in ipairs(screen.Room.Ship.Doors) do
			if door:IsClosed() then
				if screen:GetNWBool("lockMode") then
					door:Unlock()
				elseif not door:IsLocked() then
					door:LockOpen()
				end
			end
		end
		
		timer.Simple(0.1, function() screen.Room.Ship:SendShipRoomStates(ply) end)
	end)
	
	net.Receive("SysDoorToggle", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		
		screen:SetNWBool("lockMode", not screen:GetNWBool("lockMode"))
	end)
	
	function SYS:StartControlling(screen, ply)
		screen:SetNWBool("lockMode", false)
	end
	
	function SYS:ClickDoor(screen, ply, door, button)
		return false
	end
	
	function SYS:Think(dt)
		
	end
elseif CLIENT then
	SYS.Icon = Material("systems/doorcontrol.png", "smooth")

	SYS.DrawWholeShip = true
	SYS.CanClickDoors = true
	
	function SYS:Click(screen, x, y)
		if screen.Buttons then
			if screen.Buttons.CloseAll:Click(x, y) then
				net.Start("SysDoorCloseAll")
					net.WriteEntity(screen)
					net.WriteEntity(LocalPlayer())
				net.SendToServer()
			end
			if screen.Buttons.OpenAll:Click(x, y) then
				net.Start("SysDoorOpenAll")
					net.WriteEntity(screen)
					net.WriteEntity(LocalPlayer())
				net.SendToServer()
			end
			if screen.Buttons.Mode:Click(x, y) then
				net.Start("SysDoorToggle")
					net.WriteEntity(screen)
					net.WriteEntity(LocalPlayer())
				net.SendToServer()
			end
		end
	end
	
	function SYS:DrawGUI(screen)
		if not screen.Buttons then
			screen.Buttons = {}
			screen.Buttons.CloseAll = Button()
			screen.Buttons.CloseAll.X = -screen.Width / 2 + 64
			screen.Buttons.CloseAll.Y = screen.Height / 2 - 88
			screen.Buttons.CloseAll.Width = 192
			screen.Buttons.CloseAll.Height = 48
			
			screen.Buttons.OpenAll = Button()
			screen.Buttons.OpenAll.X = -96
			screen.Buttons.OpenAll.Y = screen.Height / 2 - 88
			screen.Buttons.OpenAll.Width = 192
			screen.Buttons.OpenAll.Height = 48
			
			screen.Buttons.Mode = Button()
			screen.Buttons.Mode.X = screen.Width / 2 - 192 - 64
			screen.Buttons.Mode.Y = screen.Height / 2 - 88
			screen.Buttons.Mode.Width = 192
			screen.Buttons.Mode.Height = 48
		end
		
		if screen:GetNWBool("lockMode") then
			screen.Buttons.CloseAll.Text = "LOCK ALL"
			screen.Buttons.OpenAll.Text = "UNLOCK ALL"
			screen.Buttons.Mode.Text = "LOCK/UNLOCK"
		else
			screen.Buttons.CloseAll.Text = "CLOSE ALL"
			screen.Buttons.OpenAll.Text = "OPEN ALL"
			screen.Buttons.Mode.Text = "OPEN/CLOSE"
		end
		
		surface.SetTextColor(Color(127, 127, 127, 255))
		surface.SetFont("CTextSmall")
		
		surface.DrawCentredText((screen.Buttons.CloseAll.X + screen.Buttons.CloseAll.Width + screen.Buttons.OpenAll.X) / 2,
			screen.Height / 2 - 104,
			"GLOBAL CONTROLS")
			
		surface.DrawCentredText(screen.Width / 2 - 64 - 96, screen.Height / 2 - 104,
			"CLICK MODE")
		
		for _, btn in pairs(screen.Buttons) do
			btn:Draw(screen)
		end
		
		self.Base.DrawGUI(self, screen)
	end
end
