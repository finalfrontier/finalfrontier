local BASE = "page"

local NODE_LABELS = {
	"A", "B", "C", "D", "E", "F", "G", "H",
	"I", "J", "K", "L", "M", "N", "O", "P",
	"Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z"
}

GUI.BaseName = BASE

GUI.Start = nil
GUI.End = nil
GUI.Nodes = nil
GUI.CurrSequence = nil

function GUI:GetFreeNode()
	for i = 1, #self.Nodes do
		if not table.HasValue(self.CurrSequence, i) then
			return self.Nodes[i], i
		end
	end
	return nil, 0
end

function GUI:Enter()
	self.Super[BASE].Enter(self)

	local w, h = self:GetSize()

	self.Start = sgui.Create(self, "overridenode")
	self.Start:SetSize(64, 64)
	self.Start:SetCentre(48, h / 2)
	self.Start.Enabled = false
	self.Start.CanClick = false

	self.End = sgui.Create(self, "overridenode")
	self.End:SetSize(64, 64)
	self.End:SetCentre(w - 48, h / 2)
	self.End.Enabled = false
	self.End.CanClick = false

	self.Nodes = {}

	if SERVER then
		self.CurrSequence = self.Screen.OverrideCurrSequence

		if not self.Screen.OverrideNodePositions then
			self.Screen:GenerateOverrideNodePositions(Bounds(112, 48, w - 224, h - 96))
		end

		local count = self.Screen.OverrideNodeCount
		local rows = math.ceil(count / 4)
		for i = 1, count do
			local node = sgui.Create(self, "overridenode")
			node:SetSize(64, 64)
			local pos = self.Screen.OverrideNodePositions[i]
			node:SetCentre(pos.x, pos.y)
			node.Label = NODE_LABELS[i]

			self.Nodes[i] = node
		end
	end
end

function GUI:Leave()
	self.Super[BASE].Leave(self)

	self.Nodes = nil
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if self.Nodes then
			if not layout.nodes or #layout.nodes > #self.Nodes then
				layout.nodes = {}
			end

			for i, n in ipairs(self.Nodes) do
				local x, y = n:GetCentre()
				layout.nodes[i] = { x = x, y = y, label = n.Label }
			end
		end

		if self.Screen.OverrideCurrSequence then
			layout.sequence = self.Screen.OverrideCurrSequence
		end
	end	
end

if CLIENT then
	function GUI:DrawConnectorBetween(nodeA, nodeB)
		local ax, ay = nodeA:GetGlobalCentre()
		local bx, by = nodeB:GetGlobalCentre()
		surface.DrawConnector(ax, ay, bx, by, 32)
	end

	function GUI:Draw()
		if self.CurrSequence then
			local last = self.Start
			local toSwap = nil
			surface.SetDrawColor(Color(255, 255, 255, 32))
			for i, index in ipairs(self.CurrSequence) do
				local node = self.Nodes[index]
				self:DrawConnectorBetween(last, node)
				last = node
				if not toSwap and node:IsCursorInside() then
					toSwap = {}
					toSwap.last = self.Nodes[self.CurrSequence[i - 1]] or self.Start
					toSwap.next = self.Nodes[self.CurrSequence[i + 1]] or self.End
				end
			end
			self:DrawConnectorBetween(last, self.End)
			if toSwap then
				surface.SetDrawColor(Color(45, 51, 172, 32))
				local freeNode = self:GetFreeNode()
				self:DrawConnectorBetween(toSwap.last, freeNode)
				self:DrawConnectorBetween(freeNode, toSwap.next)
			end
		end

		self.Super[BASE].Draw(self)
	end

	function GUI:UpdateLayout(layout)
		if layout.nodes then
			for i, n in ipairs(layout.nodes) do
				if not self.Nodes[i] then
					local node = sgui.Create(self, "overridenode")
					node:SetSize(64, 64)
					node:SetCentre(n.x, n.y)
					node.Label = n.label

					self.Nodes[i] = node
				end
			end
		end

		if layout.sequence then
			self.CurrSequence = layout.sequence
		end

		self.Super[BASE].UpdateLayout(self, layout)
	end	
end
