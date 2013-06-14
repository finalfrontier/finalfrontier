local BASE = "page"

GUI.BaseName = BASE

GUI._shipview = nil
GUI._powerbar = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self._shipview = sgui.Create(self, "shipview")
	self._shipview:SetCurrentShip(self:GetShip())

	for _, door in pairs(self._shipview:GetDoorElements()) do
		door.Enabled = true
		door.NeedsPermission = false
	end

	for _, room in pairs(self._shipview:GetRoomElements()) do
		if room:GetCurrentRoom() == self:GetRoom() then
			room.CanClick = true
			if SERVER then
				function room.OnClick(room, x, y, btn)
					if btn == MOUSE1 then
						self:GetSystem():ToggleAllOpen()
					else
						self:GetSystem():ToggleAllLocked()
					end
					return true
				end
			end
		elseif CLIENT then
            function room.GetRoomColor(room)
                return Color(0, 0, 0, 255)
            end
        end
	end

	local margin = 16
	local barheight = 48

	self._powerbar = sgui.Create(self, "powerbar")
	self._powerbar:SetSize(self:GetWidth() - margin * 2, barheight)
	self._powerbar:SetOrigin(margin, self:GetHeight() - margin - barheight)

	self._shipview:SetBounds(Bounds(
		margin,
		margin * 0.5,
		self:GetWidth() - margin * 2,
		self:GetHeight() - margin * 2.5 - barheight
	))
end
