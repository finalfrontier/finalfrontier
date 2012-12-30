local globAction = {}
globAction.close 	= 0
globAction.open 	= 1
globAction.lock 	= 2
globAction.unlock 	= 3

SYS.FullName = "Door Control"

function SYS:Initialize()

end

if SERVER then
	resource.AddFile("materials/systems/doorcontrol.png")

	util.AddNetworkString("SysDoorGlobal")

	net.Receive("SysDoorGlobal", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local action = net.ReadInt(8)

		for _, door in ipairs(screen.Room.Ship.Doors) do
			if action == globAction.close then
				if door:IsOpen() then
					door:UnlockClose()
				end
			elseif action == globAction.open then
				if door:IsClosed() and not door:IsLocked() then
					door:LockOpen()
				end
			elseif action == globAction.lock then
				door:Lock()
			elseif action == globAction.unlock then
				door:Unlock()
			end
		end
		
		timer.Simple(0.1, function() screen.Room.Ship:SendShipRoomStates(ply) end)
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
	
	function SYS:Click(screen, x, y, button)
		if screen.Buttons then
			for _, btn in ipairs(screen.Buttons) do
				if btn:Click(x, y) then
					net.Start("SysDoorGlobal")
						net.WriteEntity(screen)
						net.WriteEntity(LocalPlayer())
						net.WriteInt(btn.Action, 8)
					net.SendToServer()
				end
			end
		end
	end
	
	function SYS:DrawGUI(screen)
		if not screen.Buttons then
			local width = screen.Width / 4
			local nextX = -screen.Width / 2
			
			screen.Buttons = {}
			local addBtn = function(text, action)
				local btn = Button()
				btn.X = nextX + 8
				btn.Y = screen.Height / 2 - 56
				btn.Width = width - 16
				btn.Height = 48
				btn.Text = text
				btn.Action = action
				table.insert(screen.Buttons, btn)
				nextX = nextX + width
			end

			addBtn("OPEN", globAction.open)
			addBtn("CLOSE", globAction.close)
			addBtn("LOCK", globAction.lock)
			addBtn("UNLOCK", globAction.unlock)
		end
		
		surface.SetTextColor(Color(127, 127, 127, 255))
		surface.SetFont("CTextSmall")
		
		surface.DrawCentredText(0, screen.Height / 2 - 72,
			"GLOBAL CONTROLS")
			
		for _, btn in pairs(screen.Buttons) do
			btn:Draw(screen)
		end

		local margin = 16
		screen:TransformShip(screen.Ship, -screen.Width / 2 + margin, -screen.Height / 2 + margin + 64,
			screen.Width - margin * 2, screen.Height - margin * 2 - 72 - 64)
		screen:DrawShip(screen.Ship)
	end
end
