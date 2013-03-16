local BASE = "container"

GUI.BaseName = BASE

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self:SetWidth(self.Screen.Width)
	self:SetHeight(self.Screen.Height)
end

function GUI:Enter() end

function GUI:Leave()
	self:RemoveAllChildren()
end

function GUI:IsCurrentPage()
    local parent = self:GetParent()
    return parent and parent:GetCurrentPage() == self
end
