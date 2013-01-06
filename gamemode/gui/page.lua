local BASE = "container"

GUI.BaseName = BASE

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self:SetWidth(self.Screen.Width)
	self:SetHeight(self.Screen.Height)
end

function GUI:Enter() end

function GUI:Leave() 
	for _, child in pairs(self:GetChildren()) do
		child:Remove()
	end
end
