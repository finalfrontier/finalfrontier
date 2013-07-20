local BASE = "page"

GUI.BaseName = BASE

GUI._grid = nil
GUI._powerBar = nil
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

    local wpnHeight = 80

    self._weapons = {}
    for i = 1, 3 do
        local wpn = sgui.Create(self, "weaponview")
        local yof = 4 - i
        wpn:SetOrigin(self._grid:GetRight() + 8, self:GetHeight() - yof * (wpnHeight + 8))
        wpn:SetSize(colWidth, wpnHeight)
        wpn:SetWeaponSlot(moduletype.weapon1 + i - 1)
        self._weapons[i] = wpn
    end
end
