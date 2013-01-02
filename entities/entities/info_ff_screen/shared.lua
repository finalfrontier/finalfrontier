if SERVER then AddCSLuaFile("shared.lua") end

local UPDATE_FREQ = 0.5
local CURSOR_UPDATE_FREQ = 0.25
local MAX_USE_DISTANCE = 64

local NODE_LABELS = {
	"A", "B", "C", "D", "E", "F", "G", "H",
	"I", "J", "K", "L", "M", "N", "O", "P",
	"Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z"
}

local OVERRIDE_TIME_PER_NODE = 0.5

screen = {}
screen.STATUS       = 1
screen.ACCESS       = 2
screen.SYSTEM       = 3
screen.SECURITY  	= 4
screen.OVERRIDE     = 5

permission = {}
permission.NONE 	= 0
permission.ACCESS	= 1
permission.SYSTEM 	= 2
permission.SECURITY = 3

ENT.Type = "anim"
ENT.Base = "base_anim"
	
ENT.Ship = nil
ENT.Room = nil

function ENT:GetCurrentScreen()
	return self:GetNWInt("screen", screen.STATUS)
end

function ENT:IsAddingPermission()
	return self:GetNWBool("addingperm", false)
end

function ENT:IsOverriding()
	return (CurTime() - self:GetNWFloat("overridetime"))
		<= self:GetNWInt("nodecount") * OVERRIDE_TIME_PER_NODE
end

if SERVER then	
	util.AddNetworkString("CursorPos")
	util.AddNetworkString("ChangeScreen")
	util.AddNetworkString("SecurityMode")
	util.AddNetworkString("SwapNodes")
	util.AddNetworkString("Override")
	util.AddNetworkString("SysSelectRoom")
	util.AddNetworkString("SysSelectDoor")
	
	ENT.RoomName = nil

	ENT.NodeCount = 6
	ENT.Nodes = nil
	ENT.GoalSequence = nil
	ENT.CurSequence = nil

	function ENT:KeyValue(key, value)
		if key == "room" then
			self.RoomName = tostring(value)
		elseif key == "size" then
			local split = string.Explode(" ", tostring(value))
			if #split >= 1 then
				if #split >= 2 then
					self:SetNWFloat("width", tonumber(split[1]))
					self:SetNWFloat("height", tonumber(split[2]))
				else
					self:SetNWFloat("width", tonumber(split[1]))
					self:SetNWFloat("height", tonumber(split[1]))
				end
			end
		end
	end
	
	function ENT:Initialize()
		self:DrawShadow(false)
	end

	function ENT:InitPostEntity()
		if self.RoomName then
			local rooms = ents.FindByName(self.RoomName)
			if #rooms > 0 then
				self.Room = rooms[1]
				self.Room:AddScreen(self)
			end
		end
		
		if not self.Room then
			Error("Screen at " .. tostring(self:GetPos()) .. " (" .. self:GetName() .. ") has no room!\n")
			return
		end

		self:GenerateSequence()
		
		self:SetNWBool("used", false)
		self:SetNWInt("screen", screen.STATUS)
		self:SetNWFloat("overridetime", -OVERRIDE_TIME_PER_NODE * self.NodeCount)
		self:SetNWEntity("user", nil)
		self:SetNWString("ship", self.Room.ShipName)
		self:SetNWString("room", self.RoomName)
	end

	function ENT:GenerateSequence()
		self.Nodes = {}
		local temp = {}
		for i = 1, self.NodeCount do
			table.insert(self.Nodes, NODE_LABELS[i])
			if i > 1 and i < self.NodeCount then
				table.insert(temp, NODE_LABELS[i])
			end
		end
		
		local discard = math.random(#temp)
		table.remove(temp, discard)

		self.GoalSequence = {}
		self.CurSequence = {}
		table.insert(self.GoalSequence, self.Nodes[1])
		table.insert(self.CurSequence, self.Nodes[1])
		while #temp > 0 do
			local index = math.random(#temp)
			table.insert(self.GoalSequence, temp[index])
			table.insert(self.CurSequence, temp[index])
			table.remove(temp, index)
		end
		table.insert(self.GoalSequence, self.Nodes[#self.Nodes])
		table.insert(self.CurSequence, self.Nodes[#self.Nodes])

		self:SetNWInt("nodecount", self.NodeCount)

		self:ShuffleCurrentSequence()
		self:UpdateCurrentSequence()
	end

	function ENT:SwapNodes(index)
		for i = 2, #self.Nodes - 1 do
			if not table.HasValue(self.CurSequence, NODE_LABELS[i]) then
				self.CurSequence[index] = NODE_LABELS[i]
				break
			end
		end
	end

	function ENT:IsWellShuffled()
		local correct = 0
		for i = 2, #self.GoalSequence - 1 do
			if self.GoalSequence[i] == self.CurSequence[i] then
				correct = correct + 1
			end
		end

		return correct <= 1
	end

	function ENT:ShuffleCurrentSequence()
		while not self:IsWellShuffled() do
			self:SwapNodes(math.random(2, #self.CurSequence - 1))
		end
	end

	function ENT:UpdateCurrentSequence()
		local str = ""
		for i = 2, #self.CurSequence - 1 do
			str = str .. self.CurSequence[i]
		end
		self:SetNWString("sequence", str)
	end

	function ENT:ChangeGoalSequence()
		self.GoalSequence = {}
		for _, node in ipairs(self.CurSequence) do
			table.insert(self.GoalSequence, node)
		end
	end
	
	function ENT:StartOverriding()
		if self:GetNWBool("used") and not self:IsOverriding() then
			self:SetNWFloat("overridetime", CurTime())

			local str = ""
			local correct = true
			for i = 2, #self.CurSequence - 1 do
				local prev = self.CurSequence[i - 1]
				local curr = self.CurSequence[i]
				local next = self.CurSequence[i + 1]

				local score = 0
				local found = false
				for ci = 1, #self.GoalSequence do
					local goal = self.GoalSequence[ci]
					if goal == curr then
						found = true
					elseif goal == prev then
						if not found then
							score = score + 1
						else
							correct = false
						end
					elseif goal == next then
						if found or ci == #self.GoalSequence then
							score = score + 1
						else
							correct = false
						end
					end
				end
				if not found then correct = false end

				str = str .. tostring(score)
			end

			self:SetNWString("overrideinfo", str)

			if correct then
				timer.Simple(OVERRIDE_TIME_PER_NODE * (self.NodeCount - 1), function()
					local ply = self:GetNWEntity("user")
					if ply and ply:IsValid() then
						ply:SetPermission(self.Room, permission.SECURITY)
					end

					self:SetNWInt("permission", permission.SECURITY)
					self:SetNWInt("screen", screen.SECURITY)
					self:SetNWFloat("usestart", CurTime())
				end)
			end
		end
	end

	function ENT:Think()
		if self:GetNWBool("used") then
			local ply = self:GetNWEntity("user")
			if not ply:IsValid() or self:GetPos():Distance(ply:EyePos()) > MAX_USE_DISTANCE then
				self:StopUsing()
			end
		end
	end
	
	function ENT:Use(activator, caller)
		if activator:IsPlayer() then
			if not self:GetNWBool("used") and self:GetPos():Distance(activator:EyePos()) <= MAX_USE_DISTANCE then
				self:StartUsing(activator)
			elseif self:GetNWEntity("user") == activator then
				self:StopUsing()
			end
		end
	end
	
	function ENT:StartUsing(ply)
		local perm = ply:GetPermission(self.Room)
		--[[
		if perm <= permission.NONE then
			local hasPerms = false
			for _, pl in ipairs(player.GetAll()) do
				if pl:HasPermission(self.Room, permission.ACCESS) then
					hasPerms = true
					break
				end
			end
			if not hasPerms then
				perm = permission.SECURITY
			end
		end
		]]--

		self:SetNWBool("used", true)
		self:SetNWFloat("usestart", CurTime())
		self:SetNWEntity("user", ply)
		self:SetNWInt("permission", perm)
		if perm >= permission.ACCESS then
			self:SetNWInt("screen", screen.ACCESS)
		else
			self:SetNWInt("screen", screen.OVERRIDE)
		end
		self:SetNWBool("addingperm", false)
		ply:SetNWBool("usingScreen", true)
		ply:SetNWEntity("screen", self)
		ply:SetNWEntity("oldWep", ply:GetActiveWeapon())
		
		ply:SetWalkSpeed(50)
		ply:SetCanWalk(false)
		ply:CrosshairDisable()
		ply:Give("weapon_ff_unarmed")
		ply:SelectWeapon("weapon_ff_unarmed")
		
		if self.Room.System then
			self.Room.System:StartControlling(self, ply)
		end
	end
	
	function ENT:StopUsing()
		self:SetNWBool("used", false)
		self:SetNWInt("screen", screen.STATUS)
		
		local ply = self:GetNWEntity("user")
		if ply:IsValid() then
			ply:SetNWBool("usingScreen", false)
			local oldWep = ply:GetNWEntity("oldWep")
			
			ply:StripWeapon("weapon_ff_unarmed")
			if oldWep and oldWep:IsValid() then
				ply:SetActiveWeapon(oldWep)
			end
			
			ply:SetWalkSpeed(175)
			ply:SetCanWalk(true)
			ply:CrosshairEnable()
		end
		
		if self.Room.System then
			self.Room.System:StopControlling(self, ply)
		end
	end

	function ENT:ClickRoom(ply, room, button)
		if self:GetCurrentScreen() == screen.SYSTEM then
			if self.Room.System:ClickRoom(self, ply, room, button) then
				return
			end
		end

		return
	end

	function ENT:ClickDoor(ply, door, button)
		if self:GetCurrentScreen() == screen.SYSTEM then
			if self.Room.System:ClickDoor(self, ply, door, button) then
				return
			end
		elseif not ply:HasDoorPermission(door) then return end

		if button == MOUSE2 then
			if door:IsLocked() then
				door:Unlock()
			else
				door:Lock()
			end
		else
			if door:IsClosed() then
				door:LockOpen()
			else
				door:UnlockClose()
			end
		end
		
		timer.Simple(0.1, function()
			self.Room.Ship:SendShipRoomStates(ply)
		end)
	end
	
	net.Receive("CursorPos", function(len)
		local screen = net.ReadEntity()		
		screen:SetNWFloat("curx", net.ReadFloat())
		screen:SetNWFloat("cury", net.ReadFloat())
	end)

	net.Receive("ChangeScreen", function(len)
		local screen = net.ReadEntity()		
		screen:SetNWInt("screen", net.ReadInt(8))
	end)

	net.Receive("SecurityMode", function(len)
		local screen = net.ReadEntity()		
		screen:SetNWBool("addingperm", net.ReadBit() == 1)
	end)

	net.Receive("SwapNodes", function(len)
		local screen = net.ReadEntity()
		screen:SwapNodes(net.ReadInt(8))
		screen:UpdateCurrentSequence()
	end)

	net.Receive("Override", function(len)
		local screen = net.ReadEntity()
		if screen:GetNWInt("permission") < permission.SECURITY then
			screen:StartOverriding()
		else
			screen:ChangeGoalSequence()
		end
	end)
	
	net.Receive("SysSelectRoom", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local roomName = net.ReadString()
		local button = net.ReadInt(8)
		
		if string.len(roomName) > 0 then
			screen:ClickRoom(ply, ships.FindRoomByName(roomName), button)
		else
			screen:ClickRoom(ply, nil, button)
		end
	end)
	
	net.Receive("SysSelectDoor", function(len)
		local screen = net.ReadEntity()
		local ply = net.ReadEntity()
		local doorId = net.ReadInt(8)
		local button = net.ReadInt(8)
		
		screen:ClickDoor(ply, screen.Room.Ship.Doors[doorId], button)
	end)
elseif CLIENT then
	local WHITE = Material("vgui/white")

	SCREEN_DRAWSCALE = 16

	surface.CreateFont("CTextSmall", {
		font = "consolas",
		size = 32,
		weight = 400,
		antialias = true
	})
	
	surface.CreateFont("CTextLarge", {
		font = "consolas",
		size = 64,
		weight = 400,
		antialias = true
	})
	
	ENT.Width = nil
	ENT.Height = nil
	
	ENT._dialRadius = 0
	ENT._atmoCircle = nil
	ENT._shldCircle = nil
	ENT._innerCircle = nil
	
	ENT._using = false
	
	ENT._usestart = 0

	ENT._lastCursorUpdate = 0
	ENT._cursorx = 0
	ENT._cursory = 0
	ENT._lastCursorx = 0
	ENT._lastCursory = 0
	
	function ENT:Think()
		if not self.Ship and self:GetNWString("ship") then
			self.Ship = ships.FindByName(self:GetNWString("ship"))
			if self.Ship then
				self.Room = self.Ship.Rooms[self:GetNWString("room")]
			end
		end
		
		if not self.Width and self:GetNWFloat("width") then
			self.Width = self:GetNWFloat("width") * SCREEN_DRAWSCALE
			self.Height = self:GetNWFloat("height") * SCREEN_DRAWSCALE
		end
		
		if not self._using and self:GetNWBool("used") and self:GetNWEntity("user") == LocalPlayer() then
			self._using = true
		elseif self._using and (not self:GetNWBool("used") or self:GetNWEntity("user") ~= LocalPlayer()) then
			self._using = false
		end
	end

	function ENT:GetCursorPos()
		return self._cursorx, self._cursory
	end

	function ENT:DrawStatusDial(x, y, radius)
		local atmo, temp, shld = 0, 0, 0
		if self.Room then
			atmo = self.Room:GetAtmosphere()
			temp = self.Room:GetTemperature() / 600
			shld = self.Room:GetShields()
		end
		
		local scale = radius / 192
		
		local innerRad = radius / 2
		local midRad = radius * 3 / 4
		
		if not self._atmoCircle or self._dialRadius ~= radius or atmo ~= self._atmoNew then
			self._atmoCircle = CreateHollowCircle(x, y, innerRad + 2 * scale, midRad - 2 * scale, -math.pi / 2, atmo * math.pi * 2)
		end
		
		if not self._shldCircle or self._dialRadius ~= radius or shld ~= self._shldNew then
			self._shldCircle = CreateHollowCircle(x, y, midRad + 2 * scale, radius - 2 * scale, -math.pi / 2, shld * math.pi * 2)
		end
		
		if not self._innerCircle or self._dialRadius ~= radius then
			self._innerCircle = CreateCircle(x, y, innerRad - 2 * scale)
		end
		
		self._dialRadius = radius
		
		surface.SetDrawColor(Color(172, 45, 51, 255))
		surface.DrawPoly(self._innerCircle)
		
		surface.SetDrawColor(Color(0, 0, 0, 255))
		surface.DrawRect(x - radius / 2, y - radius / 2, radius, radius * (1 - temp))
		
		surface.SetDrawColor(Color(45, 51, 172, 255))
		for _, v in ipairs(self._shldCircle) do
			surface.DrawPoly(v)
		end
		surface.SetDrawColor(Color(51, 172, 45, 255))
		for _, v in ipairs(self._atmoCircle) do
			surface.DrawPoly(v)
		end
		
		surface.SetDrawColor(Color(255, 255, 255, 255))
		surface.DrawRect(x - 2 * scale, y - radius, 4 * scale, 286 * scale)
		
		for i = -4, 4 do
			if i ~= 0 then
				surface.DrawRect(x - 12 * scale, y + i * 16 * scale - 2 * scale, 24 * scale, 4 * scale)
			else
				surface.DrawRect(x - 24 * scale, y + i * 16 * scale - 2 * scale, 48 * scale, 4 * scale)
			end
		end
		
		--surface.SetTextColor(Color(255, 255, 255, 255))
		--surface.SetFont("CTextSmall")
		
		--surface.DrawCentredText(-272, -32, FormatNum(temp * 600, 3, 2) .. "K")
		--surface.DrawCentredText(-272, 32, FormatNum(atmo * 100, 3, 2) .. "kPa")
	end

	function ENT:IsCursorInsideRoom(room)
		return room.Poly and IsPointInsidePolyGroup(room.Poly.Current.ConvexPolys, { x = self._cursorx, y = self._cursory })
	end

	function ENT:IsCursorInsideDoor(door)
		return door.Poly and IsPointInsidePoly(door.Poly.Current, { x = self._cursorx, y = self._cursory })
	end

	function ENT:IsCursorInsideCircle(x, y, radius)
		local dx = x - self._cursorx
		local dy = y - self._cursory
		return dx * dx + dy * dy <= radius * radius
	end

	function ENT:IsCursorInsidePoly(poly)
		return IsPointInsidePoly(poly, { x = self._cursorx, y = self._cursory })
	end

	function ENT:GetDoorColor(door, noGlow)
		local c = 0
		if not noGlow and self:GetNWEntity("user"):HasDoorPermission(door) then	
			if self:GetCurrentScreen() == screen.ACCESS then
				c = c + (math.cos(CurTime() * math.pi * 4) + 1) * 16 + 16
			end
			if door.Poly and self:IsCursorInsideDoor(door) then
				c = c + 32
			end
		end
		if not door.Open then
			c = c + 64
			
			if door.Locked then
				return Color(c + 64, c - 64, c - 64, 255)
			end
		elseif door.Locked then
			return Color(c, c + 64, c, 255)
		end
		return Color(c, c, c, 255)
	end
	
	function ENT:FindCursorPosition()
		if self._using then
			local ang = self:GetAngles()
			local ply = LocalPlayer()
			local p0 = self:GetPos()
			local n = ang:Forward()
			local l0 = ply:GetShootPos()
			local l = ply:GetAimVector()
			
			local d = (p0 - l0):Dot(n) / l:Dot(n)
		
			local hitpos = (l0 + l * d) - p0
			local xvec = ang:Right()
			local yvec = ang:Up()
			
			self._cursorx = -hitpos:DotProduct(xvec) * SCREEN_DRAWSCALE
			self._cursory = -hitpos:DotProduct(yvec) * SCREEN_DRAWSCALE
			
			local curTime = CurTime()
			if (curTime - self._lastCursorUpdate) > CURSOR_UPDATE_FREQ then
				net.Start("CursorPos")
					net.WriteEntity(self)
					net.WriteFloat(self._cursorx)
					net.WriteFloat(self._cursory)
				net.SendToServer()
				self._lastCursorUpdate = curTime
			end
		else
			local cx = self:GetNWFloat("curx")
			local cy = self:GetNWFloat("cury")
			
			if cx ~= self._lastCursorx or cy ~= self._lastCursory then
				local t = (CurTime() - self._lastCursorUpdate) / CURSOR_UPDATE_FREQ
				
				if t >= 1 then
					self._lastCursorx = cx
					self._lastCursory = cy
					self._lastCursorUpdate = CurTime()
				else
					self._cursorx = self._lastCursorx + (cx - self._lastCursorx) * t
					self._cursory = self._lastCursory + (cy - self._lastCursory) * t
				end
			end
		end
	end
	
	function ENT:DrawCursor()
		local halfwidth = self.Width * 0.5
		local halfheight = self.Height * 0.5
		
		local boxSize = SCREEN_DRAWSCALE
		
		local x = self._cursorx
		local y = self._cursory
		
		x = math.Clamp(x, -halfwidth + boxSize * 0.5, halfwidth - boxSize * 0.5)
		y = math.Clamp(y, -halfheight + boxSize * 0.5, halfheight - boxSize * 0.5)
		
		surface.SetDrawColor(Color(255, 255, 255, 64))
		surface.DrawLine(x, -halfheight, x, halfheight)
		surface.DrawLine(-halfwidth, y, halfwidth, y)
		
		surface.SetDrawColor(Color(255, 255, 255, 127))
		surface.DrawOutlinedRect(x - boxSize * 0.5, y - boxSize * 0.5, boxSize, boxSize)
	end

	local permClrs = {
		Color(127, 127, 127, 255), 	-- NONE
		Color(45, 51, 172, 255),	-- ACCESS
		Color(51, 172, 45, 255),	-- SYSTEM
		Color(172, 45, 51, 255)		-- SECURITY
	}
	function ENT:GetPermissionColour(perm)
		return permClrs[perm + 1]
	end
	
	ENT._nodeString = nil
	ENT._sequence = nil
	ENT._freenode = nil
	function ENT:GetNodeSequence()
		local str = self:GetNWString("sequence")
		if str ~= self._nodeString then
			for _, node in pairs(self.Nodes) do
				node.Enabled = false
			end
			local nodes = {}
			local count = self:GetNWInt("nodecount")
			table.insert(nodes, self.Nodes[NODE_LABELS[1]])
			for i = 1, count - 3 do
				local node = self.Nodes[string.GetChar(str, i)]
				node.Enabled = true
				table.insert(nodes,node)
			end
			table.insert(nodes, self.Nodes[NODE_LABELS[count]])
			self._sequence = nodes
			for i = 2, count - 1 do
				local node = self.Nodes[NODE_LABELS[i]]
				if not table.HasValue(self._sequence, node) then
					self._freenode = node
					break
				end
			end
		end
		return self._sequence
	end

	function ENT:GetFreeNode()
		return self._freenode
	end

	ENT._btnRow = 0
	ENT._btnCol = 0
	ENT._btnLeft = 0
	ENT._btnTop = 0

	-- TODO: Clean up and implement pages
	function ENT:NewSecurityButtonPage(page)
		page = page or 1

		self._btnRow = 0
		self._btnCol = 0
		self._btnLeft = -self.Width / 2 + 16
		self._btnTop = -self.Height / 2 + 96

		if not self.AddBtn then
			self.AddBtn = Button()
			self.AddBtn.Width = self.Width / 2 - 32
			self.AddBtn.Height = 48
			
			self.PermBtn = Button()
			self.PermBtn.Width = self.AddBtn.Width - (self.AddBtn.Height + 8)
			self.PermBtn.Height = self.AddBtn.Height
			
			self.DelBtn = Button()
			self.DelBtn.Width = self.AddBtn.Height
			self.DelBtn.Height = self.AddBtn.Height
			self.DelBtn.Text = "X"
		end

		if self:IsAddingPermission() then
			self.SwitchBtn.Text = "MODIFY"
		else
			self.SwitchBtn.Text = "ADD NEW"
		end

		if not self.PermList then
			self.PermList = {}
			self.AddList = {}

			for i, ply in ipairs(player.GetAll()) do
				if ply:HasPermission(self.Room, permission.ACCESS) then
					table.insert(self.PermList, ply)
				else
					table.insert(self.AddList, ply)
				end
			end

			table.sort(self.AddList, function(a, b)
				return self:GetPos():DistToSqr(a:GetPos()) < self:GetPos():DistToSqr(b:GetPos())
			end)
		end
		
		surface.SetFont("CTextSmall")
		surface.SetTextColor(Color(127, 127, 127, 255))

		if self:IsAddingPermission() then
			return self.AddList
		else
			return self.PermList
		end
	end

	function ENT:NextSecurityButton(ply)
		local perm = ply:GetPermission(self.Room)
		self.AddBtn.Text = ply:Nick()
		self.PermBtn.Text = self.AddBtn.Text
		self.PermBtn.Color = self:GetPermissionColour(perm)
		self.AddBtn.X = self._btnLeft + self._btnCol * (self.PermBtn.Width + 8 + 48 + 32)
		self.AddBtn.Y = self._btnTop + self._btnRow * (self.PermBtn.Height + 16)
		self.PermBtn.X = self.AddBtn.X
		self.PermBtn.Y = self.AddBtn.Y
		self.DelBtn.X = self.PermBtn.X + self.PermBtn.Width + 8
		self.DelBtn.Y = self.PermBtn.Y

		self._btnRow = self._btnRow + 1
		if self._btnRow >= 4 then
			self._btnRow = 0
			self._btnCol = self._btnCol + 1
		end
	end

	function ENT:NewSession()
		self.TabMenu = TabMenu()
		local perm = self:GetNWInt("permission")
		if perm >= permission.ACCESS then
			self.TabMenu:AddOption("ACCESS")
		end
		if self.Room.System and perm >= permission.SYSTEM then
			self.TabMenu:AddOption("SYSTEM")
			self.Room.System:NewSession(self)
		end
		if perm >= permission.SECURITY then
			self.TabMenu:AddOption("SECURITY")
		end
		self.TabMenu:AddOption("OVERRIDE")
		self.TabMenu.X = -self.Width / 2 + 8
		self.TabMenu.Y = -self.Height / 2 + 8
		self.TabMenu.Width = self.Width - 16

		self.SwitchBtn = Button()
		self.SwitchBtn.Width = self.Width / 4 - 16
		self.SwitchBtn.Height = 64
		self.SwitchBtn.X = -self.SwitchBtn.Width / 2
		self.SwitchBtn.Y = self.Height / 2 - 64 - 16

		self.Nodes = {}
		local nodeCount = self:GetNWInt("nodecount")
		local spacing = (self.Width - 128) / (nodeCount - 1)
		local rowgap = (self.Height - 64) * 0.5
		local midy = (-self.Height / 2 + 64 + self.Height / 2 - 64) * 0.5
		for i = 1, nodeCount do
			local node = Node(NODE_LABELS[i])
			node.X = spacing * (i - 1) - self.Width / 2 + 64
			if i == 1 or i == nodeCount then
				node.Y = midy
			else
				node.Y = ((i % 2) - 0.5) * rowgap + midy
				node.X = node.X + ((i % 2) - 0.5) * -spacing
			end
			self.Nodes[NODE_LABELS[i]] = node
		end

		self.OverrideBtn = Button()
		self.OverrideBtn.Width = self.Width / 2 - 32
		self.OverrideBtn.Height = 48
		self.OverrideBtn.X = 16
		self.OverrideBtn.Y = self.Height / 2 - 64
		if self:GetNWInt("permission") < permission.SECURITY then
			self.OverrideBtn.Text = "OVERRIDE"
		else
			self.OverrideBtn.Text = "SET GOAL SEQUENCE"
		end

		local margin = 16
		self._accessTransform = self.Room:FindTransform(self,
			-self.Width / 2 + margin + 128, -self.Height / 2 + margin + 64,
			512 - margin * 2, self.Height - 64 - margin * 2)
	end

	function ENT:Draw()
		if self._usestart ~= self:GetNWFloat("usestart", 0) then
			self._usestart = self:GetNWFloat("usestart", 0)
			self:NewSession()
		end

		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)
		
		local curScreen = self:GetCurrentScreen()

		if curScreen ~= screen.STATUS and self.Room and self.Room.System
			and self.Room.System.Icon then
			local dist = 2.5
			local backPos = self:GetPos() - self:GetAngles():Forward() * dist
			cam.Start3D2D(backPos, ang, 1 / SCREEN_DRAWSCALE)
				surface.SetDrawColor(Color(255, 255, 255, 4))
				surface.SetMaterial(self.Room.System.Icon)
				local quater = self.Width / 4
				surface.DrawTexturedRect(-128 - quater, -128, 256, 256)
				surface.DrawTexturedRect(-128 + quater, -128, 256, 256)
				surface.SetMaterial(WHITE)
			cam.End3D2D()
		end

		cam.Start3D2D(self:GetPos(), ang, 1 / SCREEN_DRAWSCALE)
			if curScreen == screen.STATUS then
				self:DrawStatusDial(0, 0, 192)
				if self.Room and self.Room.System and self.Room.System.Icon then
					surface.SetDrawColor(Color(255, 255, 255, 255))
					surface.SetMaterial(self.Room.System.Icon)
					surface.DrawTexturedRect(208, -64, 128, 128)
					surface.DrawTexturedRect(-336, -64, 128, 128)
					surface.SetMaterial(WHITE)
				end
			else
				self:FindCursorPosition()
				self.TabMenu:SetCurrent(table.KeyFromValue(screen, curScreen))
				self.TabMenu:Draw(self)
				if curScreen == screen.ACCESS then
					self.Room:ApplyTransform(self._accessTransform)
					self.Room:Draw(self)
					for _, door in ipairs(self.Room.Doors) do
						door:ApplyTransform(self._accessTransform)
						door:Draw(self, self.GetDoorColor)
					end
				elseif curScreen == screen.SYSTEM then
					if self.Room and self.Room.System then
						self.Room.System:DrawGUI(self)
					else
						surface.SetTextColor(Color(64, 64, 64, 255))
						surface.SetFont("CTextLarge")
						surface.DrawCentredText(0, 0, "NO SYSTEM INSTALLED")
					end
				elseif curScreen == screen.SECURITY then
					for i, ply in ipairs(self:NewSecurityButtonPage()) do
						self:NextSecurityButton(ply)
						if not self:IsAddingPermission() then
							self.PermBtn:Draw(self)
							self.DelBtn:Draw(self)
						else
							self.AddBtn:Draw(self)
						end
					end
					self.SwitchBtn:Draw(self)
				elseif curScreen == screen.OVERRIDE then
					local overriding = self:IsOverriding()
					local sequence = self:GetNodeSequence()
					local last = nil
					local toSwap = nil
					surface.SetDrawColor(Color(255, 255, 255, 32))
					for i, node in ipairs(sequence) do
						if last then
							surface.DrawConnector(last.X, last.Y, node.X, node.Y, 32)
							if not overriding and not toSwap and node:IsCursorInside(self) then
								toSwap = {}
								toSwap.last = sequence[i - 1]
								toSwap.next = sequence[i + 1]
							end
						end
						last = node
					end
					if toSwap then
						surface.SetDrawColor(Color(255, 255, 255, 8))
						local freeNode = self:GetFreeNode()
						surface.DrawConnector(toSwap.last.X, toSwap.last.Y, freeNode.X, freeNode.Y, 32)
						surface.DrawConnector(freeNode.X, freeNode.Y, toSwap.next.X, toSwap.next.Y, 32)
					end
					for _, node in pairs(self.Nodes) do
						node:Draw(self, overriding)
					end
					if not overriding then
						self.OverrideBtn:Draw(self)
					else
						local ni = math.floor((CurTime() - self:GetNWFloat("overridetime"))
							/ OVERRIDE_TIME_PER_NODE) + 1
						local seq = self:GetNWString("sequence")
						local sta = self:GetNWString("overrideinfo")
						if ni >= 2 and ni < self:GetNWInt("nodecount") - 1 then
							local node = self.Nodes[string.GetChar(seq, ni - 1)]
							if not node:IsGlowing() then
								node:StartGlow(tonumber(string.GetChar(sta, ni - 1)) + 1)
							end
						end
					end
				end
				self:DrawCursor()
			end
		cam.End3D2D()
	end

	function ENT:ChangeScreen(nextScreen)
		net.Start("ChangeScreen")
			net.WriteEntity(self)
			net.WriteInt(nextScreen, 8)
		net.SendToServer()
		if nextScreen == screen.SECURITY then
			self.PermList = nil
		end
	end
	
	function ENT:ClickRoom(room, button)
		net.Start("SysSelectRoom")
			net.WriteEntity(self)
			net.WriteEntity(LocalPlayer())
			if room then
				net.WriteString(room:GetName())
			else
				net.WriteString("")
			end
			net.WriteInt(button, 8)
		net.SendToServer()
	end
	
	function ENT:ClickDoor(door, button)
		net.Start("SysSelectDoor")
			net.WriteEntity(self)
			net.WriteEntity(LocalPlayer())
			net.WriteInt(table.KeyFromValue(self.Ship.Doors, door), 8)
			net.WriteInt(button, 8)
		net.SendToServer()
	end

	function ENT:Click(ply, button)
		local mousePos = { x = self._cursorx, y = self._cursory }
		if self.Room then
			local index = self.TabMenu:Click(mousePos.x, mousePos.y)
			if index then
				self:ChangeScreen(screen[self.TabMenu:GetOption(index)])
			elseif self:GetCurrentScreen() == screen.ACCESS then
				for k, door in pairs(self.Room.Doors) do
					if self:IsCursorInsideDoor(door) then
						self:ClickDoor(door, button)
						return
					end
				end
			elseif self:GetCurrentScreen() == screen.SYSTEM and self.Room.System then
				local sys = self.Room.System
				if sys.CanClickRooms then
					for k, room in pairs(self.Ship.Rooms) do
						if self:IsCursorInsideRoom(room) then
							self:ClickRoom(room, button)
							return
						end
					end
				end
				
				if sys.CanClickDoors then
					for k, door in pairs(self.Ship.Doors) do
						if self:IsCursorInsideDoor(door) then
							self:ClickDoor(door, button)
							return
						end
					end
				end
				
				sys:Click(self, mousePos.x, mousePos.y, button)
			elseif self:GetCurrentScreen() == screen.SECURITY and self.PermList then
				for i, ply in ipairs(self:NewSecurityButtonPage()) do
					self:NextSecurityButton(ply)
					if not self:IsAddingPermission() then
						if self.PermBtn:Click(mousePos.x, mousePos.y) then
							local perm = ply:GetPermission(self.Room) + 1
							if perm > permission.SECURITY then perm = permission.ACCESS end
							ply:SetPermission(self.Room, perm)
							break
						end
						if self.DelBtn:Click(mousePos.x, mousePos.y) then
							ply:SetPermission(self.Room, permission.NONE)
							self.PermList = nil
							break
						end
					else
						if self.AddBtn:Click(mousePos.x, mousePos.y) then
							ply:SetPermission(self.Room, permission.ACCESS)
							self.PermList = nil
							break
						end
					end
				end
				if self.SwitchBtn:Click(mousePos.x, mousePos.y) then
					net.Start("SecurityMode")
						net.WriteEntity(self)
						net.WriteBit(not self:IsAddingPermission())
					net.SendToServer()
				end
			elseif self:GetCurrentScreen() == screen.OVERRIDE then
				if not self:IsOverriding() then
					for i, node in ipairs(self:GetNodeSequence()) do
						if node:IsCursorInside(self) then
							net.Start("SwapNodes")
								net.WriteEntity(self)
								net.WriteInt(i, 8)
							net.SendToServer()
							break
						end
					end
					if self.OverrideBtn:Click(mousePos.x, mousePos.y) then
						net.Start("Override")
							net.WriteEntity(self)
						net.SendToServer()
						if self:GetNWInt("permission") >= permission.SECURITY then
							local seq = self:GetNodeSequence()
							for i, node in ipairs(seq) do
								if i >= 2 and i < #seq then
									node:StartGlow(3)
								end
							end
						end
					end
				end
			end
		end
	end
end
