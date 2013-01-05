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
		local ox, oy = self:GetOffset()
		for _, child in pairs(self:GetChildren()) do
			if child:IsPointInside(x - ox, y - oy) then
				return true
			end
		end

		return false
	end

	function GUI:Click(x, y, button)
		local ox, oy = self:GetOffset()
		for _, child in pairs(self:GetChildren()) do
			if child:Click(x - ox, y - oy, button) then
				return
			end
		end

		self.Super[BASE].Click(self, x, y, button)
	end

	function GUI:Draw()
		self.Super[BASE].Draw(self)

		for _, child in pairs(self:GetChildren()) do
			child:Draw()
		end
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		for i, child in ipairs(self:GetChildren()) do
			local name = "c_" .. i
			if layout[name] then
				child:UpdateLayout(layout[name])
			end
		end
	end
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		for i, child in ipairs(self:GetChildren()) do
			local name = "c_" .. i
			if not layout[name] then layout[name] = {} end
			child:UpdateLayout(layout[name])
		end
	end
end
