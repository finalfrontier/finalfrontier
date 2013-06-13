local BASE = "page"

GUI.BaseName = BASE

GUI.PlayerList = nil
GUI.Buttons = nil

function GUI:UpdateButtons()
	if self.Buttons then
		for _, btn in pairs(self.Buttons) do
			btn:Remove()
		end
		self.Buttons = nil
	end

	if self.PlayerList then
		self.Buttons = {}
		for i, ply in ipairs(self.PlayerList) do
			local btn = sgui.Create(self, "securitybutton")
			btn:SetPlayer(ply)
			btn:SetSize((self:GetWidth() - 16) / 2 - 4, 48)
			btn:SetCentre(self:GetWidth() / 4, i * 48 - 16)
			table.insert(self.Buttons, btn)
		end
	end
end

function GUI:Enter()
	self.Super[BASE].Enter(self)

	if SERVER then
		self.PlayerList = player.GetAll()
		table.sort(self.PlayerList, function(a, b)
			return self:GetScreen():GetPos():DistToSqr(a:GetPos())
				< self:GetScreen():GetPos():DistToSqr(b:GetPos())
		end)

		self:UpdateButtons()
	end
end

function GUI:Leave()
	self.Super[BASE].Leave(self)

	self.PlayerList = nil
	self.Buttons = nil
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if not self.PlayerList then
			layout.players = nil
		else
			if not layout.players or #layout.players > #self.PlayerList then
				layout.players = {}
			end

			for i, ply in ipairs(self.PlayerList) do
				layout.players[i] = ply
			end
		end
	end	
end

if CLIENT then
	function GUI:UpdateLayout(layout)
		if layout.players then
			if not self.PlayerList or #self.PlayerList > #layout.players then
				self.PlayerList = {}
			end

			local changed = false
			for i, ply in pairs(layout.players) do
				if not self.PlayerList[i] or self.PlayerList[i] ~= ply then
					changed = true
					self.PlayerList[i] = ply
				end
			end

			if changed then self:UpdateButtons() end
		else
			if self.PlayerList then
				self.PlayerList = nil
				self.UpdateButtons()
			end
		end

		self.Super[BASE].UpdateLayout(self, layout)
	end	
end
