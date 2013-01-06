local BASE = "base"

GUI.BaseName = BASE

GUI._room = nil

function GUI:SetCurrentRoom(room)
	if self._room == room then return end

	self._room = room

	if CLIENT and self._room and self._bounds then
		self:FindTransform()
	end
end

function GUI:GetCurrentRoom()
	return self._room
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if self._room then
			layout.room = self._room.Index
		else
			layout.room = nil
		end
	end
end

if CLIENT then
	GUI._transform = nil

	GUI._corners = nil
	GUI._polys = nil

	GUI.Color = Color(32, 32, 32, 255)

	function GUI:SetBounds(bounds)
		self.Super[BASE].SetBounds(self, bounds)

		if self._room then
			self:FindTransform()
		end
	end

	function GUI:FindTransform()
		if not (self:GetBounds() and self._room) then return end

		local roomBounds = Bounds()
		roomBounds:AddBounds(self._room.Bounds)
		for _, door in ipairs(self._room.Doors) do
			roomBounds:AddBounds(door.Bounds)
		end
		local angle = self.Screen:GetAngles().Yaw + 90
		
		self:ApplyTransform(FindBestTransform(roomBounds,
			self:GetGlobalBounds(), false, true, angle))
	end

	function GUI:ApplyTransform(transform)
		if self._transform == transform or not self._room then return end

		self._transform = transform
		
		local x, y

		self._corners = {}
		for i, v in ipairs(self._room.Corners) do
			x, y = transform:Transform(v.x, v.y)
			self._corners[i] = { x = x, y = y }
		end

		self._polys = {}
		for j, p in ipairs(self._room.ConvexPolys) do
			self._polys[j] = {}
			for i, v in ipairs(p) do
				x, y = transform:Transform(v.x, v.y)
				self._polys[j][i] = { x = x, y = y }
			end
		end

		local centre = self._room.Bounds:GetCentre()
		x, y = transform:Transform(centre.x, centre.y)
		self._centre = { x = x, y = y }
	end

	function GUI:GetAppliedTransform()
		return self._transform
	end

	function GUI:Draw()
		if self._transform then
			local last, lx, ly = nil, 0, 0

			surface.SetDrawColor(self.Color)

			for i, poly in ipairs(self._polys) do
				surface.DrawPoly(poly)
			end

			surface.SetDrawColor(Color(255, 255, 255, 255))
			last = self._corners[#self._corners]
			lx, ly = last.x, last.y
			for _, v in ipairs(self._corners) do
				surface.DrawLine(lx, ly, v.x, v.y)
				lx, ly = v.x, v.y
			end

			local icon = self:GetSystemIcon()
			if icon then
				surface.SetMaterial(icon)
				surface.SetDrawColor(Color(255, 255, 255, 32))
				surface.DrawTexturedRect(self._centre.x - 32,
					self._centre.y - 32, 64, 64)
				surface.SetMaterial(WHITE)
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
