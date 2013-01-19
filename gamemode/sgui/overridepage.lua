local BASE = "page"

local NODE_LABELS = {
	"A", "B", "C", "D", "E", "F", "G", "H",
	"I", "J", "K", "L", "M", "N", "O", "P",
	"Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z"
}

GUI.BaseName = BASE

GUI.Nodes = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)

	self.Nodes = {}

	if SERVER then
		if not self.Screen.OverrideNodePositions then
			local w, h = self:GetSize()
			self.Screen:GenerateOverrideNodePositions(Bounds(w / 8, h / 8, w * 3 / 4, h * 3 / 4))
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

	self.Node = nil
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
	end	
end

if CLIENT then
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

		self.Super[BASE].UpdateLayout(self, layout)
	end	
end
