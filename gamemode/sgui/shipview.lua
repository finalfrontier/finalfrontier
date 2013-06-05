local BASE = "container"

GUI.BaseName = BASE

GUI._ship = nil
if CLIENT then
	GUI._shipSynced = false
end

GUI._rooms = nil
GUI._doors = nil

function GUI:GetCurrentShip()
	return self._ship
end

function GUI:SetCurrentShip(ship)
	if self._ship == ship then return end

	self._ship = ship

	if CLIENT then
		self._shipSynced = false
	end

	if not ship then
		self:RemoveAllChildren()

		self._rooms = nil
		self._doors = nil
	else
		self._doors = {}
		self._rooms = {}

		if SERVER or ship:IsCurrent() then
			self:_SetupShip()
		end
	end
end

function GUI:_SetupShip()
	for i, door in ipairs(self._ship:GetDoors()) do
		local doorview = sgui.Create(self, "doorview")
		doorview:SetCurrentDoor(door)
		self._doors[i] = doorview
	end

	for i, room in ipairs(self._ship:GetRooms()) do
		local roomview = sgui.Create(self, "roomview")
		roomview:SetCurrentRoom(room)
		self._rooms[i] = roomview
	end

	if CLIENT then
		self._shipSynced = true
		self:FindTransform()
	end
end

function GUI:GetRoomElements()
	return self._rooms
end

function GUI:GetDoorElements()
	return self._doors
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if self._ship then
			layout.ship = self._ship:GetName()
		else
			layout.ship = nil
		end
	end
end

if CLIENT then
	GUI._transform = nil

	function GUI:SetBounds(bounds)
		self.Super[BASE].SetBounds(self, bounds)
		self:FindTransform()
	end

	function GUI:FindTransform()
		if not self._ship or not self._shipSynced then return end

		self:ApplyTransform(FindBestTransform(self._ship:GetBounds(),
			self:GetGlobalBounds(), true, true))
	end

	function GUI:ApplyTransform(transform)
		if self._transform == transform or not self._ship or not self._shipSynced then return end

		self._transform = transform

		for _, room in pairs(self._rooms) do
			room:ApplyTransform(transform, true)
		end

		for _, door in pairs(self._doors) do
			door:ApplyTransform(transform)
		end
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if layout.ship then
			if not self._ship or self._ship:GetName() ~= layout.ship then
				self:SetCurrentShip(ships.GetByName(layout.ship))
			end
		else
			self._ship = nil
		end

		if self._ship and not self._shipSynced and self._ship:IsCurrent() then
			self:_SetupShip()
		end
	end
end
