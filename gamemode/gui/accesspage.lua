local BASE = "page"

GUI.BaseName = BASE

GUI.RoomView = nil
GUI.DoorViews = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.RoomView = gui.Create(self, "roomview")
	self.RoomView:SetCurrentRoom(self:GetRoom())

	self.DoorViews = {}
	if self:GetRoom() then
		for _, door in ipairs(self:GetRoom().Doors) do
			local doorview = gui.Create(self, "doorview")
			doorview:SetCurrentDoor(door)
			self.DoorViews[door] = doorview
		end
	end

	local margin = 16

	self.RoomView:SetBounds(Bounds(
		margin,
		margin,
		self:GetWidth() - margin * 2,
		self:GetHeight() - margin * 2
	))

	if CLIENT then
		for door, doorview in pairs(self.DoorViews) do
			doorview:ApplyTransform(self.RoomView:GetAppliedTransform())
		end
	end
end
