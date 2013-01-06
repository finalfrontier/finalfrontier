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
				self._permButton.Color = self.PermAccessColor
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