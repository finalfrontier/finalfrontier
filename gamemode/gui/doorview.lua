local BASE = "base"

GUI.BaseName = BASE

GUI._door = nil

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
		local trans = Transform2D()
		trans:Rotate(self._door.Angle * math.pi / 180)
		trans:Translate(self._door.X, self._door.Y)
		for i, v in ipairs(coords) do
			local x, y = transform:Transform(trans:Transform(v.x, v.y))
			self._poly[i] = { x = x, y = y }
		end
	end

	function GUI:GetAppliedTransform()
		return self._transform
	end

	function GUI:Draw()
		self.Super[BASE].Draw(self)

		if not self._transform then return end

		local last, lx, ly = nil, 0, 0

		surface.SetDrawColor(self:GetDoorColor())
		surface.DrawPoly(self._poly)
	
		surface.SetDrawColor(Color(255, 255, 255, 255))
		last = self._poly[#self._poly]
		lx, ly = last.x, last.y
		for _, v in ipairs(self._poly) do
			surface.DrawLine(lx, ly, v.x, v.y)
			lx, ly = v.x, v.y
		end
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
