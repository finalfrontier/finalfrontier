local BASE = "base"

GUI.BaseName = BASE

GUI._children = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self._children = {}
end

function GUI:UpdatePosition()
	self.Super[BASE].UpdatePosition(self)

	for _, child in pairs(self:GetChildren()) do
		child:UpdatePosition()
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
end

function GUI:RemoveChild(child)
	if table.HasValue(self._children, child) then
		table.RemoveByValue(self._children, child)
		child._parent = nil
	end
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

function GUI:Click(x, y)
	self.Super[BASE].Click(self, x, y)

	local ox, oy = self:GetOffset()
	for _, child in pairs(self:GetChildren()) do
		child:Click(x - ox, y - oy)
	end
end

if CLIENT then
	function GUI:Draw()
		self.Super[BASE].Draw(self)

		for _, child in pairs(self:GetChildren()) do
			child:Draw()
		end
	end
end
