local BASE = "base"

GUI.BaseName = BASE

GUI._children = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self._children = {}
end

function GUI:UpdateGlobalBounds()
	self.Super[BASE].UpdateGlobalBounds(self)

	for _, child in pairs(self:GetChildren()) do
		child:UpdateGlobalBounds()
	end
end

function GUI:AddChild(child)
	if child:HasParent() then
		local parent = child:GetParent()
		if parent == self then return end

		parent:RemoveChild(child)
	end

	table.insert(self._children, child)
	child._parent = self

	if child:GetBounds() then
		child:UpdateGlobalBounds()
	end
end

function GUI:RemoveChild(child)
	if table.HasValue(self._children, child) then
		table.RemoveByValue(self._children, child)
		child._parent = nil
	end
end

function GUI:RemoveAllChildren()
	for _, child in pairs(self._children) do
		child._parent = nil
	end

	self._children = {}
end

function GUI:GetChild(id)
	for _, child in pairs(self:GetChildren()) do
		if child:GetID() == id then return child end
	end
	return nil
end

function GUI:GetChildren()
	return self._children
end

function GUI:Think()
	self.Super[BASE].Think(self)

	for _, child in pairs(self:GetChildren()) do
		child:Think()
	end
end

if CLIENT then
	function IsPointInside(x, y)
		local ox, oy = self:GetLeft(), self:GetTop()
		for _, child in pairs(self:GetChildren()) do
			if child:IsPointInside(x - ox, y - oy) then
				return true
			end
		end

		return false
	end

	function GUI:Click(x, y, button)
		local ox, oy = self:GetLeft(), self:GetTop()
		for _, child in pairs(self:GetChildren()) do
			if child:Click(x - ox, y - oy, button) then
				return
			end
		end

		self.Super[BASE].Click(self, x, y, button)
	end

	function GUI:Draw()
		for _, child in pairs(self:GetChildren()) do
			child:Draw()
		end
		
		self.Super[BASE].Draw(self)
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		for i, child in ipairs(self:GetChildren()) do
			if layout[i] then
				child:UpdateLayout(layout[i])
			end
		end
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		for i, child in ipairs(self:GetChildren()) do
			if not layout[i] then layout[i] = {} end
			child:UpdateLayout(layout[i])
		end

		local i = #self:GetChildren() + 1
		while layout[i] do
			layout[i] = nil
			i = i + 1
		end
	end
end
