local BASE = "base"

GUI.BaseName = BASE

GUI._door = nil
GUI._bounds = nil

GUI.CanClick = true

GUI.Enabled = false
GUI.NeedsPermission = true

GUI.OpenLockedColor = Color(0, 64, 0, 255)
GUI.OpenUnlockedColor = Color(0, 0, 0, 255)

GUI.ClosedLockedColor = Color(127, 64, 64, 255)
GUI.ClosedUnlockedColor = Color(64, 64, 64, 255)

function GUI:SetCurrentDoor(door)
	if self._door == door then return end

	self._door = door
end

function GUI:GetCurrentDoor()
	return self._door
end

if SERVER then
	function GUI:OnClick(button)
		local ply = self:GetUsingPlayer()
		local door = self:GetCurrentDoor()

		if not self.Enabled or (self.NeedsPermission
			and not ply:HasDoorPermission(door)) then return end

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
			self:GetShip():SendShipRoomStates(ply)
		end)
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if self._door then
			layout.door = self._door.Index
		else
			layout.door = nil
		end
	end
end

if CLIENT then
	GUI._transform = nil
	GUI._poly = nil

	GUI.Color = Color(32, 32, 32, 255)

	function GUI:GetDoorColor()
		local door = self:GetCurrentDoor()
		if door.Open then
			if door.Locked then
				return self.OpenLockedColor
			else
				return self.OpenUnlockedColor
			end
		else
			if door.Locked then
				return self.ClosedLockedColor
			else
				return self.ClosedUnlockedColor
			end
		end
	end

	function GUI:ApplyTransform(transform)
		if self._transform == transform or not self._door then return end

		self._transform = transform
		
		local coords = {
			{ x = -32, y = -64 },
			{ x = -32, y =  64 },
			{ x =  32, y =  64 },
			{ x =  32, y = -64 }
		}
		
		self._poly = {}
		local bounds = Bounds()
		local ox = self:GetParent():GetGlobalLeft()
		local oy = self:GetParent():GetGlobalTop()
		local trans = Transform2D()
		trans:Rotate(self._door.Angle * math.pi / 180)
		trans:Translate(self._door.X, self._door.Y)
		for i, v in ipairs(coords) do
			local x, y = transform:Transform(trans:Transform(v.x, v.y))
			self._poly[i] = { x = x, y = y }
			bounds:AddPoint(x - ox, y - oy)
		end
		self:SetBounds(bounds)
	end

	function GUI:GetAppliedTransform()
		return self._transform
	end

	function GUI:Draw()
		if self._transform then
			local last, lx, ly = nil, 0, 0
			local ply = self:GetUsingPlayer()
			self.CanClick = self.Enabled and (not self.NeedsPermission or
				(ply and ply:HasDoorPermission(self._door)))

			surface.SetDrawColor(self:GetDoorColor())
			surface.DrawPoly(self._poly)

			if self.CanClick and self:IsCursorInside() then
				surface.SetDrawColor(Color(255, 255, 255, 16))
				surface.DrawPoly(self._poly)
			end
		
			surface.SetDrawColor(Color(255, 255, 255, 255))
			last = self._poly[#self._poly]
			lx, ly = last.x, last.y
			for _, v in ipairs(self._poly) do
				surface.DrawLine(lx, ly, v.x, v.y)
				lx, ly = v.x, v.y
			end
		end

		self.Super[BASE].Draw(self)
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if layout.room then
			if not self._room or self._room.Index ~= layout.room then
				self:SetRoom(self.Screen.Ship:GetRoomByIndex(layout.room))
			end
		else
			self._room = nil
		end
	end
end
