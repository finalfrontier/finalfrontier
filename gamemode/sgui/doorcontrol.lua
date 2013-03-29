local action = {}
action.close = 0
action.open = 1
action.lock = 2
action.unlock = 3

local BASE = "page"

GUI.BaseName = BASE

GUI.ShipView = nil
GUI.Buttons = nil

if SERVER then
	function GUI:GlobalAction(act)
		for _, door in ipairs(self:GetShip():GetDoors()) do
			if act == action.close then
				if door:IsOpen() then
					door:UnlockClose()
				end
			elseif act == action.open then
				if door:IsClosed() and not door:IsLocked() then
					door:LockOpen()
				end
			elseif act == action.lock then
				door:Lock()
			elseif act == action.unlock then
				door:Unlock()
			end
		end
	end
end

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.ShipView = sgui.Create(self, "shipview")
	self.ShipView:SetCurrentShip(self:GetShip())

	for _, door in pairs(self.ShipView:GetDoorElements()) do
		door.Enabled = true
		door.NeedsPermission = false
	end

	local margin = 16
	local buttonHeight = 48

	self.ShipView:SetBounds(Bounds(
		margin,
		margin * 0.5,
		self:GetWidth() - margin * 2,
		self:GetHeight() - margin * 2.5 - buttonHeight
	))

	self.Buttons = {
		Open = sgui.Create(self, "button"),
		Close = sgui.Create(self, "button"),
		Lock = sgui.Create(self, "button"),
		Unlock = sgui.Create(self, "button")
	}

	local width = (self:GetWidth() - margin) / table.Count(self.Buttons)
	local left = margin
	for k, btn in pairs(self.Buttons) do
		btn:SetSize(width - margin, buttonHeight)
		btn:SetOrigin(left, self:GetHeight() - margin - buttonHeight)
		btn.Text = k .. " All"
		left = left + width
	end

	if SERVER then
		function self.Buttons.Close.OnClick(btn)
			self:GlobalAction(action.close)
		end

		function self.Buttons.Open.OnClick(btn)
			self:GlobalAction(action.open)
		end

		function self.Buttons.Lock.OnClick(btn)
			self:GlobalAction(action.lock)
		end

		function self.Buttons.Unlock.OnClick(btn)
			self:GlobalAction(action.unlock)
		end
	end 
end
