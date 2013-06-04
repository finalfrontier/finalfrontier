local BASE = "base"

GUI.BaseName = BASE

GUI._innerRatio = 0.75

GUI._targ = 0
GUI._curr = 0

GUI.CurrentColour = Color(191, 191, 191, 255)
GUI.TargetColour = Color(127, 127, 127, 255)

function GUI:SetTargetValue(value)
    if value == self._targ then return end

    self._targ = value

    if CLIENT then self:_rebuildTargCircle() end
end

function GUI:GetTargetValue()
    return self._targ
end

function GUI:SetCurrentValue(value)
    if value == self._curr then return end

    self._curr = value

    if CLIENT then self:_rebuildCurrCircle() end
end

function GUI:GetCurrentValue()
    return self._curr
end

function GUI:SetInnerRatio(value)
    self._innerRatio = value

    if CLIENT then
        self:_rebuildTargCircle()
        self:_rebuildCurrCircle()
    end
end

function GUI:Initialize()
    self.Super[BASE].Initialize(self)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        layout.targ = self:GetTargetValue()
        layout.curr = self:GetCurrentValue()
        
        self.Super[BASE].UpdateLayout(self, layout)
    end
end

if CLIENT then
    GUI._targCircle = nil
    GUI._currCircle = nil

    function GUI:SetBounds(bounds)
        self.Super[BASE].SetBounds(self, bounds)

        self:_rebuildTargCircle()
        self:_rebuildCurrCircle()
    end

    function GUI:_buildCircle(value, width)
        local x, y = self:GetGlobalCentre()
        local outer = math.min(self:GetWidth(), self:GetHeight()) * 0.5
        local inner = outer * self._innerRatio
        local margin = (1.0 - width) * (outer - inner) * 0.5

        return CreateHollowCircle(x, y,
            inner + margin, outer - margin,
            -math.pi / 2, value * math.pi * 2)
    end

    function GUI:_rebuildTargCircle()
        self._targCircle = self:_buildCircle(self._targ, 1.0)
    end

    function GUI:_rebuildCurrCircle()
        self._currCircle = self:_buildCircle(self._curr, 0.5)
    end

    function GUI:Draw()
        draw.NoTexture()
        surface.SetDrawColor(self.TargetColour)
        for _, v in ipairs(self._targCircle) do
            surface.DrawPoly(v)
        end
        surface.SetDrawColor(self.CurrentColour)
        for _, v in ipairs(self._currCircle) do
            surface.DrawPoly(v)
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        self:SetTargetValue(layout.targ)
        self:SetCurrentValue(layout.curr)
    end
end
