WHITE = Material("vgui/white")

if SERVER then util.AddNetworkString("Click") end

GUI._parent = nil
GUI._bounds = nil
GUI._globBounds = nil

GUI.SyncBounds = false
GUI.CanClick = false

function GUI:Initialize()
	self._bounds = Bounds(0, 0, 0, 0)
	self._globBounds = Bounds(0, 0, 0, 0)
end

function GUI:GetRoom()
	return self.Screen.Room
end

function GUI:GetShip()
	if self.Screen.Room then
		return self.Screen.Room.Ship
	end
	return nil
end

function GUI:GetSystem()
	if self.Screen.Room then
		return self.Screen.Room.System
	end
	return nil
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

function GUI:GetBounds() return self._bounds end
function GUI:GetLeft() return self._bounds.l end
function GUI:GetTop() return self._bounds.t end
function GUI:GetRight() return self._bounds.r end
function GUI:GetBottom() return self._bounds.b end
function GUI:GetWidth() return self._bounds.r - self._bounds.l end
function GUI:GetHeight() return self._bounds.b - self._bounds.t end
function GUI:GetOrigin()
	return self._bounds.l, self._bounds.t
end
function GUI:GetSize()
	return
		self._bounds.r - self._bounds.l,
		self._bounds.b - self._bounds.t
end
function GUI:GetCentre()
	return
		(self._bounds.r + self._bounds.l) * 0.5,
		(self._bounds.t + self._bounds.b) * 0.5
end
function GUI:GetRect()
	return self._bounds.l, self._bounds.t,
		self._bounds.r - self._bounds.l,
		self._bounds.b - self._bounds.t
end

function GUI:SetBounds(bounds)
	self._bounds = bounds
	self:UpdateGlobalBounds()
end
function GUI:SetLeft(val)
	self._bounds.l = val
	self:SetBounds(self._bounds)
end
function GUI:SetTop(val)
	self._bounds.t = val
	self:SetBounds(self._bounds)
end
function GUI:SetRight(val)
	self._bounds.r = val
	self:SetBounds(self._bounds)
end
function GUI:SetBottom(val)
	self._bounds.b = val
	self:SetBounds(self._bounds)
end
function GUI:SetWidth(val)
	self._bounds.r = self._bounds.l + val
	self:SetBounds(self._bounds)
end
function GUI:SetHeight(val)
	self._bounds.b = self._bounds.t + val
	self:SetBounds(self._bounds)
end
function GUI:SetOrigin(x, y)
	local w = self:GetWidth()
	local h = self:GetHeight()
	self._bounds.l = x
	self._bounds.r = x + w
	self._bounds.t = y
	self._bounds.b = y + h
	self:SetBounds(self._bounds)
end
function GUI:SetSize(width, height)
	self._bounds.r = self._bounds.l + width
	self._bounds.b = self._bounds.t + height
	self:SetBounds(self._bounds)
end
function GUI:SetCentre(x, y)
	local hw = self:GetWidth() * 0.5
	local hh = self:GetHeight() * 0.5
	self._bounds.l = x - hw
	self._bounds.r = x + hw
	self._bounds.t = y - hh
	self._bounds.b = y + hh
	self:SetBounds(self._bounds)
end

function GUI:GetGlobalBounds() return self._globBounds end
function GUI:GetGlobalLeft() return self._globBounds.l end
function GUI:GetGlobalTop() return self._globBounds.t end
function GUI:GetGlobalRight() return self._globBounds.r end
function GUI:GetGlobalBottom() return self._globBounds.b end
function GUI:GetGlobalCentre()
	return
		(self._globBounds.r + self._globBounds.l) * 0.5,
		(self._globBounds.t + self._globBounds.b) * 0.5
end
function GUI:GetGlobalRect()
	return self._globBounds.l, self._globBounds.t,
		self._bounds.r - self._bounds.l,
		self._bounds.b - self._bounds.t
end

function GUI:UpdateGlobalBounds()
	if not self:HasParent() then
		self._globBounds.l = self._bounds.l
		self._globBounds.r = self._bounds.r
		self._globBounds.t = self._bounds.t
		self._globBounds.b = self._bounds.b
	else
		self._globBounds.l = self._bounds.l + self._parent._globBounds.l
		self._globBounds.r = self._bounds.r + self._parent._globBounds.l
		self._globBounds.t = self._bounds.t + self._parent._globBounds.t
		self._globBounds.b = self._bounds.b + self._parent._globBounds.t
	end
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

function GUI:OnClick(button)
	return
end

if CLIENT then
	function GUI:GetCursorPos()
		local x, y = self.Screen:GetCursorPos()

		if self:HasParent() then
			x = x - self._parent._globBounds.l
			y = y - self._parent._globBounds.t
		end

		return x, y
	end

	function GUI:SendIDHierarchy()
		if self:HasParent() then
			self:GetParent():SendIDHierarchy()
		end
		net.WriteInt(self:GetID(), 16)
	end

	function GUI:IsPointInside(x, y)
		return self:GetBounds():IsPointInside(x, y)
	end

	function GUI:IsCursorInside()
		return self:IsPointInside(self:GetCursorPos())
	end

	function GUI:Click(x, y, button)
		if self.CanClick and self:IsPointInside(x, y) then
			net.Start("Click")
			net.WriteEntity(self.Screen)
			self:SendIDHierarchy()
			net.WriteInt(0, 16)
			net.WriteInt(button, 8)
			net.SendToServer()
			self:OnClick(button)
			return true
		end

		return false
	end

if DEBUG then
	function GUI:Draw()
		if self.Screen:GetNWBool("used") and self:IsPointInside(self:GetCursorPos()) then
			surface.SetTextColor(0, 255, 0, 255)
			surface.SetDrawColor(0, 255, 0, 255)
		else
			surface.SetTextColor(255, 0, 0, 255)
			surface.SetDrawColor(255, 0, 0, 255)
		end

		surface.SetFont("DermaDefault")
		surface.SetTextPos(self:GetGlobalLeft() + 8, self:GetGlobalTop() + 4)
		surface.DrawText(self.Name .. " (" .. self:GetID() .. ")")

		surface.DrawOutlinedRect(self:GetGlobalLeft(), self:GetGlobalTop(),
			self:GetWidth(), self:GetHeight())

		local x, y = self:GetGlobalCentre()
		surface.DrawCircle(x, y, 8)
	end
end

	function GUI:UpdateLayout(layout)
		self._id = layout.id
		if self.SyncBounds and layout.bounds then
			self:SetBounds(Bounds(
				layout.bounds.l,
				layout.bounds.t,
				layout.bounds.r - layout.bounds.l,
				layout.bounds.b - layout.bounds.t
			))
		end
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		layout.id = self._id
		if self.SyncBounds then
			layout.bounds = {
				l = self._bounds.l,
				r = self._bounds.r,
				t = self._bounds.t,
				b = self._bounds.b
			}
		elseif layout.bounds then
			layout.bounds = nil
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
			if element and element.CanClick then
				local button = net.ReadInt(8)
				element:OnClick(button)
			end
		end
	end)
end
