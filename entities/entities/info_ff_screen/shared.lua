if SERVER then AddCSLuaFile("shared.lua") end

local UPDATE_FREQ = 0.5
local CURSOR_UPDATE_FREQ = 0.25
local MAX_USE_DISTANCE = 64

local screen = {}
screen.STATUS       = 1
screen.ACCESS       = 2
screen.SYSTEM       = 3
screen.SECURITY  	= 4
screen.OVERRIDE     = 5

local permission = {}
permission.NONE 	= 0
permission.ACCESS	= 1
permission.SYSTEM 	= 2
permission.SECURITY = 3

ENT.Type = "anim"
ENT.Base = "base_anim"
	
ENT.Ship = nil
ENT.Room = nil

if SERVER then
	util.AddNetworkString("CursorPos")
	util.AddNetworkString("ChangeScreen")
	util.AddNetworkString("SecurityMode")
	
	ENT.RoomName = nil

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
		
		self:SetNWBool("used", false)
		self:SetNWInt("screen", screen.STATUS)
		self:SetNWEntity("user", nil)
		self:SetNWString("ship", self.Room.ShipName)
		self:SetNWString("room", self.RoomName)
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

	function ENT:GetCurrentScreen()
		return self:GetNWInt("screen", screen.STATUS)
	end

	function ENT:IsAddingPermission()
		return self:GetNWBool("addingperm", false)
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
	
	function ENT:TransformShip(ship, x, y, width, height)
		local bounds = Bounds(x, y, width, height)
		if not ship.Transform or not ship.TransformBounds:Equals(bounds) then
			ship.TransformBounds = bounds
			ship.Transform = FindBestTransform(ship.Bounds, bounds, true, true)
		end
	end
	
	function ENT:DrawShip(ship, x, y, width, height)
		if not ship then return end
		
		local margin = 16
		self:TransformShip(ship, x, y, width, height)
		
		local mousePos = { x = self._cursorx, y = self._cursory }
		local last, lx, ly = nil, 0, 0
		
		for k, room in pairs(ship.Rooms) do
			if not room.ShipTrans then
				local x, y
				room.ShipTrans = {}
				room.ShipTrans.Corners = {}
				for i, v in ipairs(room.Corners) do
					x, y = ship.Transform:Transform(v.x, v.y)
					room.ShipTrans.Corners[i] = { x = x, y = y }
				end
				room.ShipTrans.ConvexPolys = {}
				for j, poly in ipairs(room.ConvexPolys) do
					room.ShipTrans.ConvexPolys[j] = {}
					for i, v in ipairs(poly) do
						x, y = ship.Transform:Transform(v.x, v.y)
						room.ShipTrans.ConvexPolys[j][i] = { x = x, y = y }
					end
				end
				local centre = room.Bounds:GetCentre()
				x, y = ship.Transform:Transform(centre.x, centre.y)
				room.ShipTrans.Centre = { x = x, y = y }
			end

			local color = self.Room.System:GetRoomColor(self, room,
				self.Room.System.CanClickRooms and
				IsPointInsidePolyGroup(room.ShipTrans.ConvexPolys, mousePos))

			for i, poly in ipairs(room.ShipTrans.ConvexPolys) do
				surface.SetDrawColor(color)
				surface.DrawPoly(poly)
			end

			surface.SetDrawColor(Color(255, 255, 255, 255))
			last = room.ShipTrans.Corners[#room.ShipTrans.Corners]
			lx, ly = last.x, last.y
			for _, v in ipairs(room.ShipTrans.Corners) do
				surface.DrawLine(lx, ly, v.x, v.y)
				lx, ly = v.x, v.y
			end

			if room.System and room.System.Icon and room.ShipTrans.Centre then
				surface.SetMaterial(room.System.Icon)
				surface.SetDrawColor(Color(255, 255, 255, 32))
				surface.DrawTexturedRect(
					room.ShipTrans.Centre.x - 12, room.ShipTrans.Centre.y - 12, 24, 24)
				surface.SetMaterial(WHITE)
			end
		end
		
		for k, door in ipairs(ship.Doors) do
			if not door.ShipTrans then
				door.ShipTrans = {}
				local coords = {
					{ x = -32, y = -64 },
					{ x = -32, y =  64 },
					{ x =  32, y =  64 },
					{ x =  32, y = -64 }
				}
				local trans = Transform2D()
				trans:Rotate(door.angle * math.pi / 180)
				trans:Translate(door.x, door.y)
				for i, v in ipairs(coords) do
					local x, y = ship.Transform:Transform(trans:Transform(v.x, v.y))
					door.ShipTrans[i] = { x = x, y = y }
				end
			end
			
			local color = self.Room.System:GetDoorColor(self, door,
				self.Room.System.CanClickDoors and
				IsPointInsidePoly(door.ShipTrans, mousePos))
			
			surface.SetDrawColor(color)
			surface.DrawPoly(door.ShipTrans)
			
			surface.SetDrawColor(Color(255, 255, 255, 255))
			last = door.ShipTrans[#door.ShipTrans]
			lx, ly = last.x, last.y
			for _, v in ipairs(door.ShipTrans) do
				surface.DrawLine(lx, ly, v.x, v.y)
				lx, ly = v.x, v.y
			end
		end
	end

	function ENT:TransformRoom(room, x, y, width, height)
		local bounds = Bounds(x, y, width, height)
		if not room.Transform or not room.TransformBounds:Equals(bounds) then
			room.TransformBounds = bounds
			local roomBounds = Bounds()
			roomBounds:AddBounds(room.Bounds)
			for _, door in ipairs(room.Doors) do
				roomBounds:AddBounds(door.Bounds)
			end
			room.Transform = FindBestTransform(roomBounds, bounds, true, true)
		end
	end

	function ENT:DrawRoom(room, x, y, width, height)
		if not room then return end
		
		local margin = 16
		self:TransformRoom(room, x, y, width, height)
		
		local mousePos = { x = self._cursorx, y = self._cursory }
		local last, lx, ly = nil, 0, 0
		
		if not room.RoomTrans then
			local x, y
			room.RoomTrans = {}
			room.RoomTrans.Corners = {}
			for i, v in ipairs(room.Corners) do
				x, y = room.Transform:Transform(v.x, v.y)
				room.RoomTrans.Corners[i] = { x = x, y = y }
			end
			room.RoomTrans.ConvexPolys = {}
			for j, poly in ipairs(room.ConvexPolys) do
				room.RoomTrans.ConvexPolys[j] = {}
				for i, v in ipairs(poly) do
					x, y = room.Transform:Transform(v.x, v.y)
					room.RoomTrans.ConvexPolys[j][i] = { x = x, y = y }
				end
			end
			local centre = room.Bounds:GetCentre()
			x, y = room.Transform:Transform(centre.x, centre.y)
			room.RoomTrans.Centre = { x = x, y = y }
		end

		local color = Color(32, 32, 32, 255)

		for i, poly in ipairs(room.RoomTrans.ConvexPolys) do
			surface.SetDrawColor(color)
			surface.DrawPoly(poly)
		end

		surface.SetDrawColor(Color(255, 255, 255, 255))
		last = room.RoomTrans.Corners[#room.RoomTrans.Corners]
		lx, ly = last.x, last.y
		for _, v in ipairs(room.RoomTrans.Corners) do
			surface.DrawLine(lx, ly, v.x, v.y)
			lx, ly = v.x, v.y
		end

		if room.System and room.System.Icon and room.RoomTrans.Centre then
			surface.SetMaterial(room.System.Icon)
			surface.SetDrawColor(Color(255, 255, 255, 32))
			surface.DrawTexturedRect(
				room.RoomTrans.Centre.x - 24, room.RoomTrans.Centre.y - 24, 48, 48)
			surface.SetMaterial(WHITE)
		end
		
		for k, door in ipairs(room.Doors) do
			if not door.RoomTrans then
				door.RoomTrans = {}
				local coords = {
					{ x = -32, y = -64 },
					{ x = -32, y =  64 },
					{ x =  32, y =  64 },
					{ x =  32, y = -64 }
				}
				local trans = Transform2D()
				trans:Rotate(door.angle * math.pi / 180)
				trans:Translate(door.x, door.y)
				for i, v in ipairs(coords) do
					local x, y = room.Transform:Transform(trans:Transform(v.x, v.y))
					door.RoomTrans[i] = { x = x, y = y }
				end
			end
			
			local color = nil
			local c = 32
			if mouseOver then
				c = c + 32
			end
			if not door.Open then
				c = c + 127
				
				if door.Locked then
					color = Color(c + 64, c - 64, c - 64, 255)
				else
					color = Color(c, c, c, 255)
				end
			elseif door.Locked then
				color = Color(c, c + 64, c, 255)
			else
				color = Color(c, c, c, 255)
			end

			surface.SetDrawColor(color)
			surface.DrawPoly(door.RoomTrans)
			
			surface.SetDrawColor(Color(255, 255, 255, 255))
			last = door.RoomTrans[#door.RoomTrans]
			lx, ly = last.x, last.y
			for _, v in ipairs(door.RoomTrans) do
				surface.DrawLine(lx, ly, v.x, v.y)
				lx, ly = v.x, v.y
			end
		end
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

		self.OverrideBtn = Button()
		self.OverrideBtn.Width = self.Width - 128
		self.OverrideBtn.Height = self.Height - 128 - self.TabMenu.Height
		self.OverrideBtn.X = -self.OverrideBtn.Width / 2
		self.OverrideBtn.Y = self.TabMenu.Y + self.TabMenu.Height + 64
		self.OverrideBtn.Text = "1337 H4X0RZ"
		self.OverrideBtn.Color = Color(51, 172, 45, 255)
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
					local margin = 16
					self:DrawRoom(self.Room, -self.Width / 2 + margin + 128,
						-self.Height / 2 + margin + 64, 512 - margin * 2,
						self.Height - 64 - margin * 2)
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
					self.OverrideBtn:Draw(self)
				end
				self:DrawCursor()
			end
		cam.End3D2D()
	end
	
	function ENT:Click(ply, button)
		local mousePos = { x = self._cursorx, y = self._cursory }
		if self.Room then
			local index = self.TabMenu:Click(mousePos.x, mousePos.y)
			if index then
				local nextScreen = screen[self.TabMenu:GetOption(index)]
				net.Start("ChangeScreen")
					net.WriteEntity(self)
					net.WriteInt(nextScreen, 8)
				net.SendToServer()
				if nextScreen == screen.SECURITY then
					self.PermList = nil
				end
			elseif self:GetCurrentScreen() == screen.SYSTEM and self.Room.System then
				local sys = self.Room.System
				if sys.CanClickRooms then
					for k, room in pairs(self.Ship.Rooms) do
						if IsPointInsidePolyGroup(room.ShipTrans.ConvexPolys, mousePos) then
							sys:ClickRoom(self, room, button)
							return
						end
					end
				end
				
				if sys.CanClickDoors then
					for k, door in pairs(self.Ship.Doors) do
						if IsPointInsidePoly(door.ShipTrans, mousePos) then
							sys:ClickDoor(self, door, button)
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
				self:SetNWInt("permission", permission.SECURITY)
				LocalPlayer():SetPermission(self.Room, permission.SECURITY)
				self:NewSession()
			end
		end
	end
end
