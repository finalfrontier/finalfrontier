SYS.FullName = "Engineering"
SYS.SGUIName = "engineering"

SYS.Powered = true

engaction = {}
engaction.compare = 1
engaction.splice = 2
engaction.mirror = 3

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

if SERVER then
    resource.AddFile("materials/systems/engineering.png")

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
        self:Reset()
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
            if self._nwdata.action ~= engaction.compare then
                prog = prog / 2
            elseif left:IsActionRequired(right, math.min(math.floor(last) + 1, 16)) then
                prog = prog / 8
            end

            prog = math.min(1, prog)
            local next = math.min(17, last + prog)
            if math.floor(last) ~= math.floor(next) then
                if next == 17 then
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
        end
    end
elseif CLIENT then
    SYS.Icon = Material("systems/engineering.png", "smooth")
end
