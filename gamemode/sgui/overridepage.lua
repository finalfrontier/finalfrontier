local BASE = "page"

local NODE_SIZE = 48

local NODE_LABELS = {
    "A", "B", "C", "D", "E", "F", "G", "H",
    "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X",
    "Y", "Z"
}

GUI.BaseName = BASE

GUI.ShuffleButton = nil
GUI.OverrideButton = nil
GUI.Start = nil
GUI.End = nil
GUI.Nodes = nil
GUI.CurrSequence = nil
GUI.CheckSequence = nil

GUI.PulseTime = 0

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

    self.ShuffleButton = sgui.Create(self, "button")
    self.ShuffleButton:SetSize(w / 4 - 24, 48)
    self.ShuffleButton:SetOrigin(16, h - 48 - 16)
    self.ShuffleButton.Text = "Shuffle"

    self.OverrideButton = sgui.Create(self, "button")
    self.OverrideButton:SetSize(w * 3 / 4 - 24, 48)
    self.OverrideButton:SetOrigin(w / 4 + 8, h - 48 - 16)

    if SERVER then
        self.ShuffleButton.OnClick = function(btn, button)
            if self.Overriding then return false end
            self:GetScreen():ShuffleCurrentOverrideSequence()
            self:GetScreen():UpdateLayout()
            return true
        end

        self.OverrideButton.OnClick = function(btn, button)
            if self.Overriding then return false end
            if self:GetPermission() < permission.SECURITY then
                self:StartOverriding()
            else
                self:GetScreen():SetOverrideSequence()
                self.PulseTime = CurTime()
                self:GetScreen():UpdateLayout()
            end
            return true
        end
    end

    h = h - 80

    self.Start = sgui.Create(self, "overridenode")
    self.Start:SetSize(NODE_SIZE, NODE_SIZE)
    self.Start:SetCentre(48, h / 2)
    self.Start.Enabled = false
    self.Start.CanClick = false

    self.End = sgui.Create(self, "overridenode")
    self.End:SetSize(NODE_SIZE, NODE_SIZE)
    self.End:SetCentre(w - 48, h / 2)
    self.End.Enabled = false
    self.End.CanClick = false

    self.Nodes = {}

    if SERVER then
        self.TimePerNode = self:GetScreen().OverrideTimePerNode
        self.CurrSequence = self:GetScreen().OverrideCurrSequence

        if not self:GetScreen().OverrideNodePositions then
            self:GetScreen():GenerateOverrideNodePositions(Bounds(112, 48, w - 224, h - 96))
        end

        local count = self:GetScreen().OverrideNodeCount
        local rows = math.ceil(count / 4)
        for i = 1, count do
            local node = sgui.Create(self, "overridenode")
            node:SetSize(NODE_SIZE, NODE_SIZE)
            local pos = self:GetScreen().OverrideNodePositions[i]
            node:SetCentre(pos.x, pos.y)
            node.Label = NODE_LABELS[i]

            local index = i
            node.OnClick = function(node, button)
                local key = table.KeyFromValue(self.CurrSequence, index)
                if key then
                    self:GetScreen():SwapOverrideNodes(key)
                    self:GetScreen():UpdateLayout()
                    return true
                end
                return false
            end

            self.Nodes[i] = node
        end
    end
end

if SERVER then
    function GUI:FindCheckSequence()
        if not self.CheckSequence then self.CheckSequence = {} end
        
        local goal = self:GetScreen().OverrideGoalSequence
        for i = 1, #self.CurrSequence do
            local last = self.CurrSequence[i - 1]
            local curr = self.CurrSequence[i]
            local next = self.CurrSequence[i + 1]

            if curr and table.HasValue(goal, curr) then
                curr = table.KeyFromValue(goal, curr)
            else curr = nil end
            if last and table.HasValue(goal, last) then
                last = table.KeyFromValue(goal, last)
            else last = 0 end
            if next and table.HasValue(goal, next) then
                next = table.KeyFromValue(goal, next)
            else next = #self.CurrSequence + 1 end

            local score = 0
            if curr then
                if last < curr then score = score + 1 end
                if curr < next then score = score + 1 end
            else
                if i == 1 or i == #self.CurrSequence or math.random() < 0.5 then score = 1 end
            end
            self.CheckSequence[i] = score
        end
    end

    function GUI:StartOverriding()
        if not self.Overriding then
            self.Overriding = true
            self.OverrideStartTime = CurTime()
            self.OverrideButton.CanClick = false

            self:FindCheckSequence()
            self:GetScreen():UpdateLayout()

            timer.Simple(self.TimePerNode * #self.Nodes, function()
                self:StopOverriding()
            end)
        end
    end

    function GUI:StopOverriding()
        if self.Overriding then
            self.Overriding = false
            self.OverrideButton.CanClick = true

            if self:IsCurrentPage() then
                local overridden = true
                for i, s in ipairs(self.CurrSequence) do
                    if self:GetScreen().OverrideGoalSequence[i] ~= s then
                        overridden = false
                    end
                end

                if overridden then
                    self.PulseTime = CurTime()
                    self:GetParent().Permission = permission.SECURITY
                    self:GetParent():UpdatePermissions()
                end

                self:GetScreen():UpdateLayout()
            end
        end
    end

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

        if self.CurrSequence then
            layout.sequence = self.CurrSequence
        end

        layout.ovrd = self.Overriding
        layout.ovrdtime = self.OverrideStartTime

        if self.Overriding then
            layout.check = self.CheckSequence
        elseif layout.check then
            layout.check = nil
        end

        layout.otpn = self.TimePerNode
        layout.pulsetime = self.PulseTime
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

            if self.CheckSequence then
                local dt = (CurTime() - self.OverrideStartTime) / self.TimePerNode
                local ni = math.floor(dt)
                dt = dt - ni
                if ni >= 0 and ni <= #self.CurrSequence then
                    local last = self.Nodes[self.CurrSequence[ni]] or self.Start
                    local next = self.Nodes[self.CurrSequence[ni + 1]] or self.End
                    if last ~= self.Start and not last:IsGlowing() then
                        last:StartGlow(self.CheckSequence[ni] + 1)
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
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if layout.nodes then
            for i, n in ipairs(layout.nodes) do
                if not self.Nodes[i] then
                    local node = sgui.Create(self, "overridenode")
                    node:SetSize(NODE_SIZE, NODE_SIZE)
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
        self.CheckSequence = layout.check

        self.TimePerNode = layout.otpn

        if layout.pulsetime ~= self.PulseTime then
            self.PulseTime = layout.pulsetime
            for _, node in pairs(self.Nodes) do
                if node.Enabled then node:StartGlow(3) end
            end
        end

        self.ShuffleButton.CanClick = not self.Overriding
        self.OverrideButton.CanClick = not self.Overriding
        
        if self:GetPermission() < permission.SECURITY then
            self.OverrideButton.Text = "Test Override Sequence"
        else
            self.OverrideButton.Text = "Set Override Sequence"
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end    
end
