-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

local BASE = "page"

local NODE_SIZE = 48

local NODE_LABELS = {
    "A", "B", "C", "D", "E", "F", "G", "H",
    "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X",
    "Y", "Z"
}

GUI.BaseName = BASE

GUI._shuffleButton = nil
GUI._overrideButton = nil
GUI._start = nil
GUI._end = nil
GUI._nodes = nil
GUI._currSequence = nil
GUI._checkSequence = nil
GUI._alarmTimer = nil

GUI._pulseTime = 0

GUI._overriding = false
GUI._overrideStartTime = 0
GUI._timePerNode = 1

function GUI:GetFreeNode()
    for i = 1, #self._nodes do
        if not table.HasValue(self._currSequence, i) then
            return self._nodes[i], i
        end
    end
    return nil, 0
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    local w, h = self:GetSize()

    self._shuffleButton = sgui.Create(self, "button")
    self._shuffleButton:SetSize((w - 48) / 4, 48)
    self._shuffleButton:SetOrigin(16, h - 48 - 16)
    self._shuffleButton.Text = "Shuffle"

    self._overrideButton = sgui.Create(self, "button")
    self._overrideButton:SetSize((w - 48) / 2, 48)
    self._overrideButton:SetOrigin(self._shuffleButton:GetRight() + 8, h - 48 - 16)

    self._alarmTimer = sgui.Create(self, "label")
    self._alarmTimer:SetSize((w - 48) / 4, 48)
    self._alarmTimer:SetOrigin(self._overrideButton:GetRight() + 8, h - 48 - 16)
    self._alarmTimer.AlignX = TEXT_ALIGN_CENTER
    self._alarmTimer.AlignY = TEXT_ALIGN_CENTER
    self._alarmTimer.Color = Color(172, 45, 51, 191)
    self._alarmTimer.Font = "CTextLarge"
    self._alarmTimer.Text = "T-60s"

    if SERVER then
        self._shuffleButton.OnClick = function(btn, button)
            if self._overriding then return false end
            self:GetScreen():ShuffleCurrentOverrideSequence()
            self:GetScreen():UpdateLayout()
            return true
        end

        self._overrideButton.OnClick = function(btn, button)
            if self._overriding then return false end
            if self:GetPermission() < permission.SECURITY then
                self:StartOverriding()
            else
                self:GetScreen():SetOverrideSequence()
                self._pulseTime = CurTime()
                self:GetScreen():UpdateLayout()
            end
            return true
        end
    end

    h = h - 80

    self._start = sgui.Create(self, "overridenode")
    self._start:SetSize(NODE_SIZE, NODE_SIZE)
    self._start:SetCentre(48, h / 2)
    self._start.Enabled = false
    self._start.CanClick = false

    self._end = sgui.Create(self, "overridenode")
    self._end:SetSize(NODE_SIZE, NODE_SIZE)
    self._end:SetCentre(w - 48, h / 2)
    self._end.Enabled = false
    self._end.CanClick = false

    self._nodes = {}

    if SERVER then
        self:GetScreen():UnpauseAlarmCountdown()

        self._timePerNode = self:GetScreen().OverrideTimePerNode
        self._currSequence = self:GetScreen().OverrideCurrSequence

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
                local key = table.KeyFromValue(self._currSequence, index)
                if key then
                    self:GetScreen():SwapOverrideNodes(key)
                    self:GetScreen():UpdateLayout()
                    return true
                end
                return false
            end

            self._nodes[i] = node
        end
    end
end

if SERVER then
    function GUI:FindCheckSequence()
        if not self._checkSequence then self._checkSequence = {} end
        
        local goal = self:GetScreen().OverrideGoalSequence
        for i = 1, #self._currSequence do
            local last = self._currSequence[i - 1]
            local curr = self._currSequence[i]
            local next = self._currSequence[i + 1]

            if curr and table.HasValue(goal, curr) then
                curr = table.KeyFromValue(goal, curr)
            else curr = nil end
            if last and table.HasValue(goal, last) then
                last = table.KeyFromValue(goal, last)
            else last = 0 end
            if next and table.HasValue(goal, next) then
                next = table.KeyFromValue(goal, next)
            else next = #self._currSequence + 1 end

            local score = 0
            if curr then
                if last < curr then score = score + 1 end
                if curr < next then score = score + 1 end
            else
                if i == 1 or i == #self._currSequence or math.random() < 0.5 then score = 1 end
            end
            self._checkSequence[i] = score
        end
    end

    function GUI:StartOverriding()
        if not self._overriding then
            self._overriding = true
            self._overrideStartTime = CurTime()
            self._overrideButton.CanClick = false

            self:FindCheckSequence()
            self:GetScreen():UpdateLayout()

            timer.Simple(self._timePerNode * #self._nodes, function()
                self:StopOverriding()
            end)
        end
    end

    function GUI:StopOverriding()
        if self._overriding then
            self._overriding = false
            self._overrideButton.CanClick = true

            if self:IsCurrentPage() then
                local overridden = true
                for i, s in ipairs(self._currSequence) do
                    if self:GetScreen().OverrideGoalSequence[i] ~= s then
                        overridden = false
                    end
                end

                if overridden then
                    self:GetScreen():StopAlarmCountdown()
                    self._pulseTime = CurTime()
                    self:GetParent().Permission = permission.SECURITY
                    self:GetParent():UpdatePermissions()
                else
                    self:GetScreen():StartAlarmCountdown()
                end

                self:GetScreen():UpdateLayout()
            end
        end
    end

    function GUI:Leave()
        self.Super[BASE].Leave(self)

        self:GetScreen():PauseAlarmCountdown()
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if self._nodes then
            if not layout.nodes or #layout.nodes > #self._nodes then
                layout.nodes = {}
            end

            for i, n in ipairs(self._nodes) do
                local x, y = n:GetCentre()
                layout.nodes[i] = { x = x, y = y, label = n.Label }
            end
        end

        if self._currSequence then
            layout.sequence = self._currSequence
        end

        layout.ovrd = self._overriding
        layout.ovrdtime = self._overrideStartTime

        if self._overriding then
            layout.check = self._checkSequence
        elseif layout.check then
            layout.check = nil
        end

        layout.otpn = self._timePerNode
        layout.pulsetime = self._pulseTime
    end
end

if CLIENT then
    function GUI:DrawConnectorBetween(nodeA, nodeB)
        local ax, ay = nodeA:GetGlobalCentre()
        local bx, by = nodeB:GetGlobalCentre()
        surface.DrawConnector(ax, ay, bx, by, 32)
    end

    function GUI:Draw()
        if self._currSequence then
            local freeNode = self:GetFreeNode()
            freeNode.Enabled = false
            freeNode.CanClick = false
            local last = self._start
            local toSwap = nil
            surface.SetDrawColor(Color(255, 255, 255, 32))
            for i, index in ipairs(self._currSequence) do
                local node = self._nodes[index]
                node.Enabled = true
                node.CanClick = not self._overriding
                self:DrawConnectorBetween(last, node)
                last = node
                if not self._overriding and not toSwap and node:IsCursorInside() then
                    toSwap = {}
                    toSwap.last = self._nodes[self._currSequence[i - 1]] or self._start
                    toSwap.next = self._nodes[self._currSequence[i + 1]] or self._end
                end
            end
            self:DrawConnectorBetween(last, self._end)
            if toSwap then
                surface.SetDrawColor(Color(255, 255, 255,
                    math.cos(CurTime() * math.pi * 2) * 24 + 32))
                self:DrawConnectorBetween(toSwap.last, freeNode)
                self:DrawConnectorBetween(freeNode, toSwap.next)
            end

            if self._checkSequence then
                local dt = (CurTime() - self._overrideStartTime) / self._timePerNode
                local ni = math.floor(dt)
                dt = dt - ni
                if ni >= 0 and ni <= #self._currSequence then
                    local last = self._nodes[self._currSequence[ni]] or self._start
                    local next = self._nodes[self._currSequence[ni + 1]] or self._end
                    if last ~= self._start and not last:IsGlowing() then
                        last:StartGlow(self._checkSequence[ni] + 1)
                    end
                    local lx, ly = last:GetGlobalCentre()
                    local nx, ny = next:GetGlobalCentre()
                    local x = lx + (nx - lx) * dt
                    local y = ly + (ny - ly) * dt
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawCircle(x, y, math.cos((CurTime() - self._overrideStartTime)
                        * math.pi * 2 / self._timePerNode) * 4 + 16)
                end
            end
        end

        self._alarmTimer.Text = self:GetScreen():GetFormattedAlarmCounter()

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if layout.nodes then
            for i, n in ipairs(layout.nodes) do
                if not self._nodes[i] then
                    local node = sgui.Create(self, "overridenode")
                    node:SetSize(NODE_SIZE, NODE_SIZE)
                    node:SetCentre(n.x, n.y)
                    node.Label = n.label

                    self._nodes[i] = node
                end
            end
        end

        if layout.sequence then
            self._currSequence = layout.sequence
        end

        self._overriding = layout.ovrd
        self._overrideStartTime = layout.ovrdtime
        self._checkSequence = layout.check

        self._timePerNode = layout.otpn

        if layout.pulsetime ~= self._pulseTime then
            self._pulseTime = layout.pulsetime
            for _, node in pairs(self._nodes) do
                if node.Enabled then node:StartGlow(3) end
            end
        end

        self._shuffleButton.CanClick = not self._overriding
        self._overrideButton.CanClick = not self._overriding
        
        if self:GetPermission() < permission.SECURITY then
            self._overrideButton.Text = "Attempt Override"
        else
            self._overrideButton.Text = "Set Sequence"
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end    
end
