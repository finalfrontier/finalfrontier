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

	ENT.NextGUIID = 1

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
				self.Width = self:GetNWFloat("width") * SCREEN_DRAWSCALE
				self.Height = self:GetNWFloat("height") * SCREEN_DRAWSCALE
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
				self.Ship = self.Room.Ship
			end
		end
		
		if not self.Room then
			Error("Screen at " .. tostring(self:GetPos()) .. " (" .. self:GetName() .. ") has no room!\n")
			return
		end

		self:SetNWString("ship", self.Room.ShipName)
		self:SetNWString("room", self.RoomName)
		self:SetNWBool("used", false)
		self:SetNWEntity("user", nil)

		self.UI = sgui.Create(self, MAIN_GUI_CLASS)
		self:UpdateLayout()
	end

	function ENT:UpdateLayout()
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
		self:SetNWFloat("usestart", CurTime())
		self:SetNWEntity("user", ply)
		ply:SetNWBool("usingScreen", true)
		ply:SetNWEntity("screen", self)
		ply:SetNWEntity("oldWep", ply:GetActiveWeapon())
		
		ply:SetWalkSpeed(50)
		ply:SetCanWalk(false)
		ply:CrosshairDisable()
		ply:Give("weapon_ff_unarmed")
		ply:SelectWeapon("weapon_ff_unarmed")

		self.UI:SetCurrentPage(page.ACCESS)
		self:UpdateLayout()

		if self.Room.System then
			self.Room.System:StartControlling(self, ply)
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

		if self.Room.System then
			self.Room.System:StopControlling(self, ply)
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
	local WHITE = Material("vgui/white")

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

	ENT._using = false
	ENT._usestart = 0

	ENT._lastCursorUpdate = 0
	ENT._cursorx = 0
	ENT._cursory = 0
	ENT._lastCursorx = 0
	ENT._lastCursory = 0
	
	function ENT:UpdateLayout()
		if not self.UI then
			self.UI = sgui.Create(self, MAIN_GUI_CLASS)
		end

		self.Layout = self:GetNWTable("layout")
		if self.Layout then
			self.UI:UpdateLayout(self.Layout)
		end
	end

	function ENT:Think()
		if not self.Ship and self:GetNWString("ship") then
			self.Ship = ships.FindByName(self:GetNWString("ship"))
			if self.Ship then
				self.Room = self.Ship.Rooms[self:GetNWString("room")]
			end
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

	function ENT:NewSession()

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

	function ENT:Draw()
		if self._usestart ~= self:GetNWFloat("usestart", 0) then
			self._usestart = self:GetNWFloat("usestart", 0)
			self:NewSession()
		end

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
