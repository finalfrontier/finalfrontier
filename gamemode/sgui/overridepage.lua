local BASE = "page"

local NODE_LABELS = {
	"A", "B", "C", "D", "E", "F", "G", "H",
	"I", "J", "K", "L", "M", "N", "O", "P",
	"Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z"
}

GUI.BaseName = BASE

GUI.OverrideButton = nil
GUI.Start = nil
GUI.End = nil
GUI.Nodes = nil
GUI.CurrSequence = nil

GUI.Overriding = false
GUI.OverrideStartTime = 0
GUI.TimePerNode = 1

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

	self.OverrideButton = sgui.Create(self, "button")
	self.OverrideButton:SetSize(w - 32, 48)
	self.OverrideButton:SetCentre(w / 2, h - 24 - 16)
	self.OverrideButton.Text = "Test Override Sequence"

	if SERVER then
		self.OverrideButton.OnClick = function(btn, button)
			if not self.Overriding then
				self.Overriding = true
				self.OverrideStartTime = CurTime()
				self.OverrideButton.CanClick = false

				self.Screen:UpdateLayout()

				timer.Simple(self.TimePerNode * #self.Nodes, function()
					self.Overriding = false
					self.OverrideButton.CanClick = true

					self.Screen:UpdateLayout()
				end)
			end
		end
	end

	h = h - 80

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
		self.TimePerNode = self.Screen.OverrideTimePerNode
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

			local index = i
			node.OnClick = function(node, button)
				self.Screen:SwapOverrideNodes(table.KeyFromValue(self.CurrSequence, index))
				self.Screen:UpdateLayout()
			end

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

		layout.ovrd = self.Overriding
		layout.ovrdtime = self.OverrideStartTime

		layout.otpn = self.TimePerNode
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
			local freeNode = self:GetFreeNode()
			freeNode.Enabled = false
			freeNode.CanClick = false
			local last = self.Start
			local toSwap = nil
			surface.SetDrawColor(Color(255, 255, 255, 32))
			for i, index in ipairs(self.CurrSequence) do
				local node = self.Nodes[index]
				node.Enabled = true
				node.CanClick = not self.Overriding
				self:DrawConnectorBetween(last, node)
				last = node
				if not self.Overriding and not toSwap and node:IsCursorInside() then
					toSwap = {}
					toSwap.last = self.Nodes[self.CurrSequence[i - 1]] or self.Start
					toSwap.next = self.Nodes[self.CurrSequence[i + 1]] or self.End
				end
			end
			self:DrawConnectorBetween(last, self.End)
			if toSwap then
				surface.SetDrawColor(Color(255, 255, 255,
					math.cos(CurTime() * math.pi * 2) * 24 + 32))
				self:DrawConnectorBetween(toSwap.last, freeNode)
				self:DrawConnectorBetween(freeNode, toSwap.next)
			end

			local dt = (CurTime() - self.OverrideStartTime) / self.TimePerNode
			local ni = math.floor(dt)
			dt = dt - ni
			if ni >= 0 and ni <= #self.CurrSequence then
				local last = self.Nodes[self.CurrSequence[ni]] or self.Start
				local next = self.Nodes[self.CurrSequence[ni + 1]] or self.End
				if last ~= self.Start and not last:IsGlowing() then
					last:StartGlow(1)
				end
				local lx, ly = last:GetGlobalCentre()
				local nx, ny = next:GetGlobalCentre()
				local x = lx + (nx - lx) * dt
				local y = ly + (ny - ly) * dt
				surface.SetDrawColor(Color(255, 255, 255, 255))
				surface.DrawCircle(x, y, math.cos((CurTime() - self.OverrideStartTime)
					* math.pi * 2 / self.TimePerNode) * 4 + 16)
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

		self.Overriding = layout.ovrd
		self.OverrideStartTime = layout.ovrdtime

		self.TimePerNode = layout.otpn

		self.OverrideButton.CanClick = not self.Overriding

		self.Super[BASE].UpdateLayout(self, layout)
	end	
end
