local BASE = "page"

GUI.BaseName = BASE

GUI._grids = nil
GUI._compareBtn = nil
GUI._repairBtn = nil
GUI._mirrorBtn = nil

GUI._progressBar = nil
GUI._powerBar = nil

function GUI:CreateModuleView(slot)
    local size = math.min(self:GetHeight() - 144, self:GetWidth() / 2 - 128)

    local view = sgui.Create(self, "moduleview")
    view:SetTop(8)
    if slot == moduletype.repair1 then
        view:SetLeft(16)
    else
        view:SetLeft(self:GetWidth() - size - 16)
    end
    view:SetSize(size, size)
    view:SetSlot(slot)
    return view
end

function GUI:Enter()
    self._grids = {}

    self._grids[1] = self:CreateModuleView(moduletype.repair1)
    self._grids[2] = self:CreateModuleView(moduletype.repair2)

    self._compareBtn = sgui.Create(self, "button")
    self._compareBtn:SetSize(self._grids[2]:GetLeft() - self._grids[1]:GetRight() - 32, 48)
    self._compareBtn:SetCentre(self:GetWidth() / 2, 8 + self._grids[1]:GetHeight() / 6)
    self._compareBtn.Text = "Compare"

    self._repairBtn = sgui.Create(self, "button")
    self._repairBtn:SetSize(self._grids[2]:GetLeft() - self._grids[1]:GetRight() - 32, 48)
    self._repairBtn:SetCentre(self:GetWidth() / 2, 8 + self._grids[1]:GetHeight() * 3 / 6)
    self._repairBtn.Text = "Splice"

    self._mirrorBtn = sgui.Create(self, "button")
    self._mirrorBtn:SetSize(self._grids[2]:GetLeft() - self._grids[1]:GetRight() - 32, 48)
    self._mirrorBtn:SetCentre(self:GetWidth() / 2, 8 + self._grids[1]:GetHeight() * 5 / 6)
    self._mirrorBtn.Text = "Transcribe"

    self._progressBar = sgui.Create(self, "slider")
    self._progressBar:SetOrigin(16, self._grids[1]:GetBottom() + 16)
    self._progressBar:SetSize(self:GetWidth() - 32, 48)
    self._progressBar.CanClick = false

    self._powerBar = sgui.Create(self, "powerbar")
    self._powerBar:SetOrigin(16, self._progressBar:GetBottom() + 8)
    self._powerBar:SetSize(self:GetWidth() - 32, 48)
end

if CLIENT then
    function GUI:Draw()
        local left = self._grids[1]:GetModule()
        local right = self._grids[2]:GetModule()
        local loaded = true == (left and right and left:IsGridLoaded() and right:IsGridLoaded())
        self._compareBtn.CanClick = loaded and left:GetModuleType() == right:GetModuleType()
        self._repairBtn.CanClick = loaded and (left:GetDamaged() > 0 or right:GetDamaged() > 0)
        self._mirrorBtn.CanClick = loaded and (left:GetDamaged() > 0 or right:GetDamaged() > 0)

        self.Super[BASE].Draw(self)
    end
end
