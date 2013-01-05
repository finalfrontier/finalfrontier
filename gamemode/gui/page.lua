local BASE = "container"

GUI.BaseName = BASE

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self:SetWidth(self.Screen.Width)
	self:SetHeight(self.Screen.Height)
end

function GUI:Leave() end
function GUI:Enter()
	self:SetWidth(self:GetParent():GetWidth())
	self:SetHeight(self:GetParent():GetHeight())
end
