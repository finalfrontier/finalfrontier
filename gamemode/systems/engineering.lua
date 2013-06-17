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

        self:Reset()
        self._nwdata.compresult = compresult.none
    end

    function SYS:Reset()
        self._nwdata.progress = -1
        self._nwdata.action = 0
        self:_UpdateNWData()
    end

    function SYS:StartAction(type)
        if not self:IsPerformingAction() then
            self._nwdata.action = type
            self._nwdata.progress = 0
            self._nwdata.compresult = compresult.none
            self:_UpdateNWData()
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

                if self._nwdata.action == engaction.splice then
                    left:Splice(right, math.floor(next))
                    right:Splice(left, math.floor(next))
                elseif self._nwdata.action == engaction.mirror then
                    left:Mirror(right, math.floor(next))
                    right:Mirror(left, math.floor(next))
                end
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
