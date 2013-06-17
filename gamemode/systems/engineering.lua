SYS.FullName = "Engineering"
SYS.SGUIName = "engineering"

SYS.Powered = true

engaction = {}
engaction.compare = 1
engaction.splice = 2
engaction.mirror = 3

compresult = {}
compresult.none = 0
compresult.left = 1
compresult.right = 2
compresult.equal = 3

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
    return self:GetRoom():GetModule(moduletype.repair1),
        self:GetRoom():GetModule(moduletype.repair2)
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
            if self._nwdata.action == engaction.compare then
                return 0.5
            else
                return 1
            end
        end
        return 0
    end

    function SYS:Initialize()
        self._compared = {nil, nil}
        self._sounds = {}

        self:Reset()
        self._nwdata.compresult = compresult.none
    end

    function SYS:Reset()
        self._nwdata.progress = -1
        self._nwdata.action = 0
        self:_UpdateNWData()

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
            self._nwdata.compresult = compresult.none
            self:_UpdateNWData()

            self._sounds[1] = CreateSound(left, "ambient/machines/electric_machine.wav")
            self._sounds[2] = CreateSound(right, "ambient/machines/electric_machine.wav")

            self._sounds[1]:PlayEx(0.5, 75)
            self._sounds[2]:PlayEx(0.5, 75)

            self:UpdateSounds(1)
        end
    end

    function SYS:UpdateSounds(index)
        if self._nwdata.action == engaction.compare then return end

        local left, right = self:GetModules()
        for i, v in pairs(self._sounds) do
            if index > 16 then
                v:ChangePitch(50, 0.5)
                v:ChangeVolume(0, 0.75)
            elseif left:IsDamaged(index) ~= right:IsDamaged(index)
                and (self._nwdata.action == engaction.splice) == (((i == 1 and left:IsDamaged(index))
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
            local prog = dt * self:GetPower() * 2 / self:GetPowerNeeded()
            local index = math.min(math.floor(last) + 1, 16)
            if self._nwdata.action == engaction.compare then
                prog = prog / 2
            elseif left:IsDamaged(index) ~= right:IsDamaged(index) then
                prog = prog / 8
            end

            prog = math.min(1, prog)
            local next = math.min(17, last + prog)
            if math.floor(last) ~= math.floor(next) then
                if next == 17 then
                    if self._nwdata.action == engaction.compare then
                        local lscore = left:GetScore()
                        local rscore = right:GetScore()

                        self._compared[1] = left
                        self._compared[2] = right

                        if lscore == rscore then
                            self._nwdata.compresult = compresult.equal
                        elseif lscore > rscore then
                            self._nwdata.compresult = compresult.left
                        else
                            self._nwdata.compresult = compresult.right
                        end
                    end

                    self:Reset()
                    return
                end
                
                local index = math.floor(next)

                if index > 0 then
                    self:UpdateSounds(math.max(1, index + 1))

                    if self._nwdata.action == engaction.splice then
                        left:Splice(right, index)
                        right:Splice(left, index)
                    elseif self._nwdata.action == engaction.mirror then
                        left:Mirror(right, index)
                        right:Mirror(left, index)
                    end
                end
            elseif self._nwdata.action ~= engaction.compare
                and left:IsDamaged(index) ~= right:IsDamaged(index) then
                local ed = EffectData()
                if left:IsDamaged(index) == (self._nwdata.action == engaction.splice) then
                    ed:SetEntity(left)
                else
                    ed:SetEntity(right)
                end
                ed:SetMagnitude(0.25 + math.random() * 0.25)
                ed:SetFlags(1)
                util.Effect("module_sparks", ed, true, true)
            end

            self._nwdata.progress = next
            self:_UpdateNWData()
        elseif self:GetComparisonResult() ~= compresult.none then
            local left, right = self:GetModules()

            if left ~= self._compared[1] or right ~= self._compared[2] then
                self._nwdata.compresult = compresult.none
                self:_UpdateNWData()
            end
        end
    end
elseif CLIENT then
    SYS.Icon = Material("systems/engineering.png", "smooth")
end
