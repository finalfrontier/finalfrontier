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

GUI.BaseName = BASE

GUI._grids = nil
GUI._compareBtn = nil
GUI._spliceBtn = nil
GUI._mirrorBtn = nil

GUI._progressBar = nil
GUI._powerBar = nil

function GUI:CreateModuleView(slot)
    local size = math.min(self:GetHeight() - 144, self:GetWidth() / 2 - 128)

    local view = sgui.Create(self, "moduleview")
    view:SetTop(8)
    if slot == moduletype.REPAIR_1 then
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

    self._grids[1] = self:CreateModuleView(moduletype.REPAIR_1)
    self._grids[2] = self:CreateModuleView(moduletype.REPAIR_2)

    self._compareBtn = sgui.Create(self, "button")
    self._compareBtn:SetSize(self._grids[2]:GetLeft() - self._grids[1]:GetRight() - 32, 48)
    self._compareBtn:SetCentre(self:GetWidth() / 2, 8 + self._grids[1]:GetHeight() / 6)
    self._compareBtn.Text = "Compare"

    self._spliceBtn = sgui.Create(self, "button")
    self._spliceBtn:SetSize(self._grids[2]:GetLeft() - self._grids[1]:GetRight() - 32, 48)
    self._spliceBtn:SetCentre(self:GetWidth() / 2, 8 + self._grids[1]:GetHeight() * 3 / 6)
    self._spliceBtn.Text = "Splice"

    self._mirrorBtn = sgui.Create(self, "button")
    self._mirrorBtn:SetSize(self._grids[2]:GetLeft() - self._grids[1]:GetRight() - 32, 48)
    self._mirrorBtn:SetCentre(self:GetWidth() / 2, 8 + self._grids[1]:GetHeight() * 5 / 6)
    self._mirrorBtn.Text = "Transcribe"

    if SERVER then
        function self._compareBtn.OnClick(btn, x, y, button)
            self:GetSystem():StartAction(engaction.COMPARE)
        end

        function self._spliceBtn.OnClick(btn, x, y, button)
            self:GetSystem():StartAction(engaction.SPLICE)
        end

        function self._mirrorBtn.OnClick(btn, x, y, button)
            self:GetSystem():StartAction(engaction.TRANSCRIBE)
        end
    end

    self._progressBar = sgui.Create(self, "slider")
    self._progressBar:SetOrigin(16, self._grids[1]:GetBottom() + 16)
    self._progressBar:SetSize(self:GetWidth() - 32, 48)
    self._progressBar.CanClick = false

    if CLIENT then
        function self._progressBar.GetValueText(bar, value)
            local left = self._grids[1]:GetModule()
            local right = self._grids[2]:GetModule()
            local system = self:GetSystem()
            local act = system:GetCurrentAction()
            local pc = tostring(math.Round(value * 100)) .. "%"

            if not left and not right then
                return "INSERT MODULES TO BEGIN"
            elseif not left then
                return "INSERT LEFT MODULE TO BEGIN"
            elseif not right then
                return "INSERT RIGHT MODULE TO BEGIN"
            elseif not system:IsPerformingAction() then
                local comp = system:GetComparisonResult()
                if comp == compresult.EQUAL then
                    return "BOTH MODULES ARE EQUALLY EFFICIENT"
                elseif comp == compresult.LEFT then
                    return "LEFT MODULE IS MORE EFFICIENT"
                elseif comp == compresult.RIGHT then
                    return "RIGHT MODULE IS MORE EFFICIENT"
                else
                    return "SELECT AN ACTION"
                end
            elseif act == engaction.COMPARE then
                return "COMPARISON IN PROGRESS " .. pc
            elseif act == engaction.SPLICE then
                return "SPLICING IN PROGRESS " .. pc
            elseif act == engaction.TRANSCRIBE then
                return "TRANSCRIPTION IN PROGRESS " .. pc
            end
        end

        function self._progressBar.DrawValueText(bar, value)
            local text = bar:GetValueText(value)
            surface.SetFont("CTextSmall")
            local x, y = bar:GetGlobalCentre()
            local wid, hei = surface.GetTextSize(text)
            if self:GetSystem():IsPerformingAction() then
                surface.SetTextColor(bar.TextColorPos)
            else
                surface.SetTextColor(bar.DisabledColor)
            end
            surface.SetTextPos(x - wid / 2, y - hei / 2)
            surface.DrawText(text)
        end
    end

    self._powerBar = sgui.Create(self, "powerbar")
    self._powerBar:SetOrigin(16, self._progressBar:GetBottom() + 8)
    self._powerBar:SetSize(self:GetWidth() - 32, 48)
end

if CLIENT then
    function GUI:Draw()
        local left = self._grids[1]:GetModule()
        local right = self._grids[2]:GetModule()
        local loaded = true == (left and right and left:IsGridLoaded() and right:IsGridLoaded())
            and not self:GetSystem():IsPerformingAction()
        self._compareBtn.CanClick = loaded and left:GetModuleType() == right:GetModuleType()
        self._spliceBtn.CanClick = loaded and (left:GetDamaged() > 0 or right:GetDamaged() > 0)
        self._mirrorBtn.CanClick = loaded and (left:GetDamaged() > 0 or right:GetDamaged() > 0)

        self._progressBar.Value = math.min(self:GetSystem():GetActionProgress() / 16, 1)

        self.Super[BASE].Draw(self)
    end
end
