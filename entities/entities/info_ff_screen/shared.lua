if SERVER then AddCSLuaFile("shared.lua") end

local SCREEN_DRAWSCALE = 16

local UPDATE_FREQ = 0.5
local CURSOR_UPDATE_FREQ = 0.25
local MAX_USE_DISTANCE = 64

local MAIN_GUI_CLASS = "screen"

ENT.Type = "anim"
ENT.Base = "base_anim"
	
ENT.Ship = nil
ENT.Room = nil

ENT.Width = 0
ENT.Height = 0

ENT.UI = nil
ENT.Layout = nil

if SERVER then	
	util.AddNetworkString("CursorPos")
	
	ENT.RoomName = nil

	ENT.OverrideNodeCount = 4
	ENT.OverrideTimePerNode = 0.5

	ENT.OverrideNodePositions = nil
	ENT.OverrideGoalSequence = nil
	ENT.OverrideCurrSequence = nil

	ENT.NextGUIID = 1
	ENT.FreeGUIIDs = nil

	function ENT:KeyValue(key, value)
		if key == "room" then
			self.RoomName = tostring(value)
		elseif key == "width" then
			self:SetNWFloat("width", tonumber(value))
			self.Width = self:GetNWFloat("width") * SCREEN_DRAWSCALE
		elseif key == "height" then
			self:SetNWFloat("height", tonumber(value))
			self.Height = self:GetNWFloat("height") * SCREEN_DRAWSCALE
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
				self.Ship = self.Room:GetShip()
			end
		end
		
		if not self.Room then
			Error("Screen at " .. tostring(self:GetPos()) .. " (" .. self:GetName() .. ") has no room!\n")
			return
		end

		self:SetNWString("ship", self.Room:GetShipName())
		self:SetNWString("room", self.RoomName)
		self:SetNWBool("used", false)
		self:SetNWEntity("user", nil)

		self:GenerateOverrideSequence()
		-- if not DEBUG then self:ShuffleCurrentOverrideSequence() end

		self.FreeGUIIDs = {}

		self.UI = sgui.Create(self, MAIN_GUI_CLASS)
		self.UI:AllocateNewID()
		self:UpdateLayout()
	end

	function ENT:FreeGUIID(id)
		if id == self.NextGUIID - 1 then
			self.NextGUIID = id
			while #self.FreeGUIIDs > 0 and self.FreeGUIIDs[#self.FreeGUIIDs] == id - 1 do
				table.remove(self.FreeGUIIDs, #self.FreeGUIIDs)
				id = id - 1
				self.NextGUIID = id
			end
		else
			table.insert(self.FreeGUIIDs, id)
		end
	end

	function ENT:GenerateOverrideNodePositions(bounds)
		self.OverrideNodePositions = {}
		local left, top, width, height = bounds:GetRect()
		for i = 1, self.OverrideNodeCount do
			local bestScore = 0
			local bestx, besty
			for j = 1, 1024 do
				local x = left + math.random() * width
				local y = top + math.random() * height
				local min = width * width + height * height
				for k, pos in pairs(self.OverrideNodePositions) do
					local xd, yd = pos.x - x, pos.y - y
					local d2 = xd * xd + yd * yd
					if d2 < min then
						min = d2
					end
				end
				if min >= bestScore then
					bestScore = min
					bestx = x
					besty = y
				end
			end
			self.OverrideNodePositions[i] = { x = bestx, y = besty }
		end
		table.sort(self.OverrideNodePositions, function(a, b)
			return b.x > a.x
		end)
	end

	function ENT:GenerateOverrideSequence()
		local temp = {}
		for i = 1, self.OverrideNodeCount do
			table.insert(temp, i)
		end

		table.remove(temp, math.random(#temp))

		self.OverrideGoalSequence = {}
		self.OverrideCurrSequence = {}
		while #temp > 0 do
			local index = math.random(#temp)
			table.insert(self.OverrideGoalSequence, temp[index])
			table.insert(self.OverrideCurrSequence, temp[index])
			table.remove(temp, index)
		end
	end

	function ENT:SwapOverrideNodes(index)
		if index < 1 or index > #self.OverrideCurrSequence then return end
		for i = 1, self.OverrideNodeCount do
			if not table.HasValue(self.OverrideCurrSequence, i) then
				self.OverrideCurrSequence[index] = i
				break
			end
		end
	end

	function ENT:GetCurrentOverrideSequenceScore()
		local correct = 0
		for i = 1, #self.OverrideGoalSequence do
			if self.OverrideGoalSequence[i] == self.OverrideCurrSequence[i] then
				correct = correct + 1
			end
		end
		return correct
	end

	function ENT:IsOverrideWellShuffled(score)
		score = score or self:GetCurrentOverrideSequenceScore()
		local limit = 0
		return self:GetCurrentOverrideSequenceScore() <= limit
	end

	function ENT:CloneCurrentOverrideSequence()
		local clone = {}
		for i, v in ipairs(self.OverrideCurrSequence) do
			clone[i] = v
		end
		return clone
	end

	function ENT:ShuffleCurrentOverrideSequence()
		local tries = 0
		local best = self:CloneCurrentOverrideSequence()
		local bestScore = self:GetCurrentOverrideSequenceScore()
		while tries < 256 do
			self:SwapOverrideNodes(math.random(1, #self.OverrideCurrSequence))

			if tries >= 2 * #self.OverrideCurrSequence then
				local score = self:GetCurrentOverrideSequenceScore()
				if self:IsOverrideWellShuffled(score) then
					return
				elseif score < bestScore then
					best = self:CloneCurrentOverrideSequence()
					bestScore = score
				end
			end

			tries = tries + 1
		end

		self.OverrideCurrSequence = best
	end

	function ENT:SetOverrideSequence()
		for i, v in ipairs(self.OverrideCurrSequence) do
			self.OverrideGoalSequence[i] = v
		end
	end

	function ENT:UpdateLayout()
		if not self.UI then return end
		if not self.Layout then self.Layout = {} end

		self.UI:UpdateLayout(self.Layout)
		self:SetNWTable("layout", self.Layout)
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
		if self:GetNWBool("used", false) then return end

		self:SetNWBool("used", true)
		self:SetNWEntity("user", ply)
		ply:SetNWBool("usingScreen", true)
		ply:SetNWEntity("screen", self)
		ply:SetNWEntity("oldWep", ply:GetActiveWeapon())
		
		ply:SetWalkSpeed(50)
		ply:SetCanWalk(false)
		ply:CrosshairDisable()
		ply:Give("weapon_ff_unarmed")
		ply:SelectWeapon("weapon_ff_unarmed")

		self.UI.Permission = ply:GetPermission(self.Room)
		self.UI:SetCurrentPage(page.ACCESS)
		self:UpdateLayout()

		if self.Room:HasSystem() then
			self.Room:GetSystem():StartControlling(self, ply)
		end
	end
	
	function ENT:StopUsing()
		if not self:GetNWBool("used", false) then return end

		self:SetNWBool("used", false)
		
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

		self.UI:SetCurrentPage(page.STATUS)
		self:UpdateLayout()

		if self.Room:HasSystem() then
			self.Room:GetSystem():StopControlling(self, ply)
		end
	end

	function ENT:GetCursorPos()
		return self:GetNWFloat("curx"), self:GetNWFloat("cury")
	end

	function ENT:Click(button)
		if self.UI then
			self.UI:Click(self:GetCursorPos())
		end
	end

	net.Receive("CursorPos", function(len, ply)
		local screen = net.ReadEntity()
		if screen:GetNWEntity("user") == ply then
			screen:SetNWFloat("curx", net.ReadFloat())
			screen:SetNWFloat("cury", net.ReadFloat())
		end
	end)
elseif CLIENT then
	ENT._using = false

	ENT._lastCursorUpdate = 0
	ENT._cursorx = 0
	ENT._cursory = 0
	ENT._lastCursorx = 0
	ENT._lastCursory = 0
	ENT._nextCursorx = 0
	ENT._nextCursory = 0
	
	function ENT:UpdateLayout()
		if not self.Layout and self.Room and self.Room:IsCurrent() and self.Ship == LocalPlayer():GetShip() then
			self.Layout = self:GetNWTable("layout")
		elseif self.UI and self.Ship and self.Room and self.Ship ~= LocalPlayer():GetShip() then
			self.Layout = nil
			self:ForgetNWTable("layout")
		end

		if not self.UI and self.Layout and self:IsNWTableCurrent("layout") then
			self.UI = sgui.Create(self, MAIN_GUI_CLASS)
		elseif self.UI and not self.Layout then
			self.UI = nil
		end

		if self.Layout and table.Count(self.Layout) > 0 then
			self.UI:UpdateLayout(self.Layout)
		end
	end

	function ENT:Think()
		if self.Ship and not self.Ship:IsValid() then
			self.Ship = nil
			self.Room = nil
		end

		if not self.Ship and self:GetNWString("ship") then
			self.Ship = ships.GetByName(self:GetNWString("ship"))
		end

		if not self.Room and self.Ship and self:GetNWString("room") then
			self.Room = self.Ship:GetRoomByName(self:GetNWString("room"))
		end
		
		self.Width = self:GetNWFloat("width") * SCREEN_DRAWSCALE
		self.Height = self:GetNWFloat("height") * SCREEN_DRAWSCALE

		self:UpdateLayout()
		
		if not self._using and self:GetNWBool("used") and self:GetNWEntity("user") == LocalPlayer() then
			self._using = true
		elseif self._using and (not self:GetNWBool("used") or self:GetNWEntity("user") ~= LocalPlayer()) then
			self._using = false
		end
	end

	function ENT:GetCursorPos()
		return self._cursorx, self._cursory
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
					self._lastCursorx = self._nextCursorx
					self._lastCursory = self._nextCursory
					self._cursorx = self._nextCursorx
					self._cursory = self._nextCursory
					self._nextCursorx = cx
					self._nextCursory = cy
					self._lastCursorUpdate = CurTime()
				else
					self._cursorx = self._lastCursorx + (self._nextCursorx - self._lastCursorx) * t
					self._cursory = self._lastCursory + (self._nextCursory - self._lastCursory) * t
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

	function ENT:Draw()
		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)
		
		cam.Start3D2D(self:GetPos(), ang, 1 / SCREEN_DRAWSCALE)
			if self.UI then
				self.UI:Draw()
			end
			if self:GetNWBool("used") then
				self:FindCursorPosition()
				self:DrawCursor()
			end
		cam.End3D2D()
	end

	function ENT:Click(button)
		if self.UI then
			local x, y = self:GetCursorPos()
			self.UI:Click(x, y, button)
		end
	end
end
