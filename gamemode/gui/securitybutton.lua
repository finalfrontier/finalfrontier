local BASE = "container"

GUI.BaseName = BASE

GUI.PermNoneColor = Color(127, 127, 127, 255)
GUI.PermAccessColor = Color(45, 51, 172, 255)
GUI.PermSystemColor = Color(51, 172, 45, 255)
GUI.PermSecurityColor = Color(172, 45, 51, 255)

GUI._player = nil

GUI._permButton = nil
GUI._adrmButton = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self._permButton = gui.Create(self, "button")
	self._adrmButton = gui.Create(self, "button")

	if SERVER then
		self._permButton.OnClick = function(btn)
			local ply = self:GetPlayer()
			local room = self:GetRoom()
			if not ply then return end
			local perm = ply:GetPermission(room)
			perm = perm + 1
			if perm > permission.SECURITY then perm = permission.ACCESS end
			ply:SetPermission(self:GetRoom(), perm)
		end

		self._adrmButton.OnClick = function(btn)
			local ply = self:GetPlayer()
			local room = self:GetRoom()
			if not ply then return end

			if ply:GetPermission(room) <= permission.NONE then
				ply:SetPermission(self:GetRoom(), permission.ACCESS)
			else
				ply:SetPermission(self:GetRoom(), permission.NONE)
			end
		end
	end

	self._adrmButton.Text = "X"
end

function GUI:SetBounds(bounds)
	self.Super[BASE].SetBounds(self, bounds)

	self._permButton:SetWidth(self:GetWidth() - self:GetHeight())
	self._adrmButton:SetWidth(self:GetHeight())
	self._permButton:SetHeight(self:GetHeight())
	self._adrmButton:SetHeight(self:GetHeight())

	self._adrmButton:SetOrigin(self._permButton:GetRight(), 0)
end

function GUI:GetPlayer()
	return self._player
end

function GUI:SetPlayer(ply)
	self._player = ply
	self._permButton.Text = ply:Nick()
end

if CLIENT then
	function GUI:Draw()
		if self._player then
			self._adrmButton.Text = "-"
			self._permButton.CanClick = true
			local perm = self._player:GetPermission(self:GetRoom())
			if perm >= permission.SECURITY then
				self._permButton.Color = self.PermSecurityColor
			elseif perm >= permission.SYSTEM then
				self._permButton.Color = self.PermSystemColor
			elseif perm >= permission.ACCESS then
				self._permButton.Color = self.PermAccessColor
			else
				self._permButton.Color = self.PermNoneColor
				self._adrmButton.Text = "+"
				self._permButton.CanClick = false
			end
		end

		self.Super[BASE].Draw(self)
	end
end