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

SYS.FullName = "Engineering"
SYS.SGUIName = "engineering"

SYS.Powered = true

engaction = {}
engaction.COMPARE = 1
engaction.SPLICE = 2
engaction.TRANSCRIBE = 3

compresult = {}
compresult.NONE = 0
compresult.LEFT = 1
compresult.RIGHT = 2
compresult.EQUAL = 3

function SYS:IsPerformingAction()
    return self._nwdata.progress >= 0
end

function SYS:GetActionProgress()
    return math.max(0, self._nwdata.progress)
end

function SYS:GetCurrentAction()
    return self._nwdata.action
end

function SYS:GetModules()
    return self:GetRoom():GetModule(moduletype.REPAIR_1),
        self:GetRoom():GetModule(moduletype.REPAIR_2)
end

function SYS:GetComparisonResult()
    return self._nwdata.compresult
end

if SERVER then
    resource.AddFile("materials/systems/engineering.png")

    SYS._compared = nil
    SYS._sounds = nil

    function SYS:CalculatePowerNeeded(dt)
        if self:IsPerformingAction() then
            local score = self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)
            if self._nwdata.action == engaction.COMPARE then
                return 0.5 + score * 0.25
            else
                return 2 + score
            end
        end
        return 0
    end

    function SYS:Initialize()
        self._compared = {nil, nil}
        self._sounds = {}

        self:Reset()
        self._nwdata.compresult = compresult.NONE
    end

    function SYS:Reset()
        self._nwdata.progress = -1
        self._nwdata.action = 0
        self._nwdata:Update()

        for _, v in pairs(self._sounds) do
            v:Stop()
        end

        self._sounds = {}
    end

    function SYS:StartAction(type)
        local left, right = self:GetModules()
        if not self:IsPerformingAction() and left and right then
            self._nwdata.action = type
            self._nwdata.progress = 0
            self._nwdata.compresult = compresult.NONE
            self._nwdata:Update()

            self._sounds[1] = CreateSound(left, "ambient/machines/electric_machine.wav")
            self._sounds[2] = CreateSound(right, "ambient/machines/electric_machine.wav")

            self._sounds[1]:PlayEx(0.5, 75)
            self._sounds[2]:PlayEx(0.5, 75)

            self:UpdateSounds(1)
        end
    end

    function SYS:UpdateSounds(index)
        if self._nwdata.action == engaction.COMPARE then return end

        local left, right = self:GetModules()
        for i, v in pairs(self._sounds) do
            if index > 16 then
                v:ChangePitch(50, 0.5)
                v:ChangeVolume(0, 0.75)
            elseif left:IsDamaged(index) ~= right:IsDamaged(index)
                and (self._nwdata.action == engaction.SPLICE) == (((i == 1 and left:IsDamaged(index))
                or (i == 2 and right:IsDamaged(index)))) then
                v:ChangePitch(100, 0.5)
                v:ChangeVolume(1, 0.75)
            else
                v:ChangePitch(75, 0.5)
                v:ChangeVolume(0.5, 0.75)
            end
        end
    end

    function SYS:Think(dt)
        if self:IsPerformingAction() then
            local left, right = self:GetModules()
            if not IsValid(left) or not IsValid(right) then
                self:Reset()
                return
            end

            local last = self:GetActionProgress()
            local score = self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)
            local prog = dt * self:GetPower() * (1 + score * 2) * 2 / self:GetPowerNeeded()
            local index = math.min(math.floor(last) + 1, 16)
            if self._nwdata.action == engaction.COMPARE then
                prog = prog / 2
            elseif left:IsDamaged(index) ~= right:IsDamaged(index) then
                prog = prog / 12
            end

            prog = math.min(1, prog)
            local next = math.min(17, last + prog)
            if math.floor(last) ~= math.floor(next) then
                next = math.floor(next)
                if next == 17 then
                    if self._nwdata.action == engaction.COMPARE then
                        local lscore = left:GetScore()
                        local rscore = right:GetScore()

                        self._compared[1] = left
                        self._compared[2] = right

                        if lscore == rscore then
                            self._nwdata.compresult = compresult.EQUAL
                        elseif lscore > rscore then
                            self._nwdata.compresult = compresult.LEFT
                        else
                            self._nwdata.compresult = compresult.RIGHT
                        end
                    end

                    self:Reset()
                    return
                elseif next > 0 then
                    self:UpdateSounds(math.max(1, next + 1))

                    if self._nwdata.action == engaction.SPLICE then
                        left:Splice(right, next)
                        right:Splice(left, next)
                    elseif self._nwdata.action == engaction.TRANSCRIBE then
                        left:Transcribe(right, next)
                        right:Transcribe(left, next)
                    end
                end
            elseif self._nwdata.action ~= engaction.COMPARE
                and left:IsDamaged(index) ~= right:IsDamaged(index) then
                local ed = EffectData()
                if left:IsDamaged(index) == (self._nwdata.action == engaction.SPLICE) then
                    ed:SetEntity(left)
                    ed:SetOrigin(left:GetPos() + Vector(0, 0, 8))
                else
                    ed:SetEntity(right)
                    ed:SetOrigin(right:GetPos() + Vector(0, 0, 8))
                end
                ed:SetMagnitude(0.25 + math.random() * 0.25)
                ed:SetFlags(1)
                util.Effect("module_sparks", ed, true, true)
            end

            self._nwdata.progress = next
            self._nwdata:Update()
        elseif self:GetComparisonResult() ~= compresult.NONE then
            local left, right = self:GetModules()

            if left ~= self._compared[1] or right ~= self._compared[2] then
                self._nwdata.compresult = compresult.NONE
                self._nwdata:Update()
            end
        end
    end
elseif CLIENT then
    SYS.Icon = Material("systems/engineering.png", "smooth")
end
