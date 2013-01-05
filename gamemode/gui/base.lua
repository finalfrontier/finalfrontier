WHITE = Material("vgui/white")

if SERVER then util.AddNetworkString("Click") end

GUI._parent = nil

GUI._offsetx = 0
GUI._offsety = 0

GUI._posx = 0
GUI._posy = 0

GUI.SyncPosition = false

function GUI:GetRoom()
	return self.Screen.Room
end

function GUI:GetShip()
	if self.Screen.Room then
		return self.Screen.Room.Ship
	end
end

function GUI:GetSystem()
	return self.Screen.Room.System
end

function GUI:GetSystemIcon()
	if self.Screen.Room and self.Screen.Room.System then
		return self.Screen.Room.System.Icon
	end

	return nil
end

function GUI:GetUsingPlayer()
	return self.Screen:GetNWEntity("user")
end

function GUI:GetOffset()
	return self._offsetx, self._offsety
end

function GUI:SetOffset(x, y)
	if x then self._offsetx = x end
	if y then self._offsety = y end

	if x or y then
		self:UpdatePosition()
	end
end

function GUI:UpdatePosition()
	self._posx = self._offsetx
	self._posy = self._offsety

	if self:HasParent() then
		local addx, addy = self:GetParent():GetPos()
		self._posx = self._posx + addx
		self._posy = self._posy + addy
	end
end

function GUI:GetPos()
	return self._posx, self._posy
end

function GUI:Remove()
	if self:HasParent() then
		self:GetParent():RemoveChild(self)
	end
end

function GUI:HasParent()
	return self._parent ~= nil
end

function GUI:GetParent()
	return self._parent
end

if CLIENT then
	function GUI:GetCursorPos()
		local x, y = self.Screen:GetCursorPos()

		if self:HasParent() then
			x = x - self._parent._posx
			y = y - self._parent._posy
		end

		return x, y
	end

	function GUI:SendIDHierarchy()
		if self:HasParent() then
			self:GetParent():SendIDHierarchy()
		end
		net.WriteInt(self:GetID(), 16)
	end

	function GUI:OnClick(button)
		net.Start("Click")
		net.WriteEntity(self.Screen)
		self:SendIDHierarchy()
		net.WriteInt(0, 16)
		net.WriteInt(button, 8)
		net.SendToServer()
	end

	function GUI:IsPointInside(x, y)
		return false
	end

	function GUI:Click(x, y, button)
		if self:IsPointInside(x, y) then
			self:OnClick(button)
			return true
		end

		return false
	end

	function GUI:UpdateLayout(layout)
		self._id = layout.id
		if self.SyncPosition and layout.x and layout.y then
			self:SetOffset(layout.x, layout.y)
		end
	end
end

if SERVER then
	function GUI:OnClick(button)
		return
	end

	function GUI:UpdateLayout(layout)
		layout.id = self._id
		if self.SyncPosition then
			layout.x, layout.y = self:GetOffset()
		elseif layout.x or layout.y then
			layout.x, layout.y = nil, nil
		end
	end

	net.Receive("Click", function(len, ply)
		local screen = net.ReadEntity()
		if screen:GetNWEntity("user") == ply then
			local element = nil
			while true do
				local id = net.ReadInt(16)
				if element == nil then
					if id == screen.UI:GetID() then
						element = screen.UI
					else return end
				else
					if id == 0 then break end
					if not element.GetChild then return end
					element = element:GetChild(id)
					if not element then return end
				end
			end
			if element then
				local button = net.ReadInt(8)
				element:OnClick(button)
			end
		end
	end)
end
