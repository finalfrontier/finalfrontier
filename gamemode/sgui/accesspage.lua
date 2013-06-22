local BASE = "page"

GUI.BaseName = BASE

GUI._roomView = nil
GUI._doorViews = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._roomView = sgui.Create(self:GetScreen(), "roomview")
    self._roomView:SetCurrentRoom(self:GetRoom())

    self._doorViews = {}
    if self:GetRoom() then
        for _, door in ipairs(self:GetRoom():GetDoors()) do
            local doorview = sgui.Create(self, "doorview")
            doorview:SetCurrentDoor(door)
            doorview.Enabled = true
            doorview.NeedsPermission = true
            self._doorViews[door] = doorview
        end
    end

    self:AddChild(self._roomView)

    local margin = 16

    self._roomView:SetBounds(Bounds(
        margin,
        margin,
        self:GetWidth() - margin * 2,
        self:GetHeight() - margin * 2
    ))

    if CLIENT then
        for door, doorview in pairs(self._doorViews) do
            doorview:ApplyTransform(self._roomView:GetAppliedTransform())
        end
    end
end
