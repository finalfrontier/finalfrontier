local BASE = "page"

GUI.BaseName = BASE

GUI._grid = nil
GUI._powerBar = nil
GUI._targetBtn = nil
GUI._directBtn = nil
GUI._weapons = nil

function GUI:Enter()
    local gridSize = self:GetHeight() - 16
    local colWidth = self:GetWidth() - gridSize - 24
    self._grid = sgui.Create(self, "sectorgrid")
    self._grid:SetOrigin(8, 8)
    self._grid:SetSize(gridSize, gridSize)
    self._grid:SetCentreObject(nil)
    self._grid:SetScale(math.max(self._grid:GetMinScale(), self._grid:GetMinSensorScale()))

    self._powerBar = sgui.Create(self, "powerbar")
    self._powerBar:SetOrigin(self._grid:GetRight() + 8, 8)
    self._powerBar:SetSize(colWidth, 48)

    self._targetBtn = sgui.Create(self, "button")
    self._targetBtn:SetOrigin(self._powerBar:GetLeft(), self._powerBar:GetBottom() + 8)
    self._targetBtn:SetSize((colWidth - 8) / 2, 48)
    self._targetBtn.Text = "Set Target"

    self._directBtn = sgui.Create(self, "button")
    self._directBtn:SetOrigin(self._targetBtn:GetRight() + 8, self._powerBar:GetBottom() + 8)
    self._directBtn:SetSize((colWidth - 8) / 2, 48)
    self._directBtn.Text = "Set Angle"

    local wpnHeight = 80

    self._weapons = {}
    for i = 1, 3 do
        local wpn = sgui.Create(self, "weaponview")
        local yof = 4 - i
        local slot = moduletype.weapon1 + i - 1

        wpn:SetOrigin(self._grid:GetRight() + 8, self:GetHeight() - yof * (wpnHeight + 8))
        wpn:SetSize(colWidth, wpnHeight)
        wpn:SetWeaponSlot(slot)
        
        if SERVER then
            wpn.OnClick = function(wpn, x, y, button)
                local mdl = wpn:GetWeaponModule()
                if mdl and mdl:CanShoot() then
                    self:GetSystem():FireWeapon(slot, self:GetShip(), 45)
                end
            end
        end
        
        self._weapons[i] = wpn
    end
end
